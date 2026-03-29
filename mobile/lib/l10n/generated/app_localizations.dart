import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FlyFy'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your World,\nPersonalized.'**
  String get welcomeTitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Experience the ultimate travel super app designed for the modern explorer.'**
  String get welcomeDescription;

  /// No description provided for @welcomeToFlyFy.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FlyFy'**
  String get welcomeToFlyFy;

  /// No description provided for @authByPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get authByPhone;

  /// No description provided for @termsAgreementText.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our <terms>Terms of Service</terms> and <privacy>Privacy Policy</privacy>'**
  String get termsAgreementText;

  /// No description provided for @enterPhoneToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue'**
  String get enterPhoneToContinue;

  /// No description provided for @verifyAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyAndLogin;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get verifyYourPhone;

  /// No description provided for @enterAuthCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we just sent to\n'**
  String get enterAuthCode;

  /// No description provided for @didntReceiveOTP.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveOTP;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @googleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Google.'**
  String get googleLoginFailed;

  /// No description provided for @appleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Apple ID.'**
  String get appleLoginFailed;

  /// No description provided for @otpSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code.'**
  String get otpSendFailed;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get otpInvalid;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneRequiredError;

  /// No description provided for @phoneInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get phoneInvalidError;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get homeWelcomeBack;

  /// No description provided for @homeTravelQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to travel next?'**
  String get homeTravelQuestion;

  /// No description provided for @homeExploreServices.
  ///
  /// In en, this message translates to:
  /// **'Explore Services'**
  String get homeExploreServices;

  /// No description provided for @serviceTours.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get serviceTours;

  /// No description provided for @serviceGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get serviceGuides;

  /// No description provided for @serviceHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get serviceHotels;

  /// No description provided for @serviceTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get serviceTransport;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out? You may need to authenticate again next time.'**
  String get logoutDialogMessage;

  /// No description provided for @logoutConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutConfirmButton;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String codeSentTo(Object phone);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Profile is not available'**
  String get profileNotAvailable;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileLocale.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLocale;

  /// No description provided for @profileTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get profileTimezone;

  /// No description provided for @profileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountry;

  /// No description provided for @profileCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get profileCurrency;

  /// No description provided for @profileVisibility.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility'**
  String get profileVisibility;

  /// No description provided for @profilePublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get profilePublic;

  /// No description provided for @profilePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get profilePrivate;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileButton;

  /// No description provided for @becomeGuideButton.
  ///
  /// In en, this message translates to:
  /// **'Become a guide'**
  String get becomeGuideButton;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(Object name);

  /// No description provided for @openProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to open profile'**
  String get openProfileHint;

  /// No description provided for @userFallbackName.
  ///
  /// In en, this message translates to:
  /// **'friend'**
  String get userFallbackName;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @loginWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with biometrics'**
  String get loginWithBiometrics;

  /// No description provided for @biometricLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with biometrics'**
  String get biometricLoginFailed;

  /// No description provided for @appLockLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking your protected session'**
  String get appLockLoading;

  /// No description provided for @appLockSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get appLockSetupTitle;

  /// No description provided for @appLockSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'You will use this PIN for quick access if the session expires after reopening the app.'**
  String get appLockSetupDescription;

  /// No description provided for @appLockSetupConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again to confirm and save it.'**
  String get appLockSetupConfirmDescription;

  /// No description provided for @appLockSetupCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get appLockSetupCreateButton;

  /// No description provided for @appLockSetupConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get appLockSetupConfirmButton;

  /// No description provided for @appLockSetupMismatch.
  ///
  /// In en, this message translates to:
  /// **'PIN codes do not match'**
  String get appLockSetupMismatch;

  /// No description provided for @appLockPinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 4-digit PIN'**
  String get appLockPinInvalid;

  /// No description provided for @appLockPinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get appLockPinIncorrect;

  /// No description provided for @appLockUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm sign in'**
  String get appLockUnlockTitle;

  /// No description provided for @appLockPinUnlockDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue using the app.'**
  String get appLockPinUnlockDescription;

  /// No description provided for @appLockBiometricUnlockDescription.
  ///
  /// In en, this message translates to:
  /// **'Confirm access with Face ID or biometrics. After 3 failed attempts, PIN unlock will be shown.'**
  String get appLockBiometricUnlockDescription;

  /// No description provided for @appLockUsePinButton.
  ///
  /// In en, this message translates to:
  /// **'Use PIN'**
  String get appLockUsePinButton;

  /// No description provided for @appLockUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlockButton;

  /// No description provided for @appLockRetryBiometricButton.
  ///
  /// In en, this message translates to:
  /// **'Scan face'**
  String get appLockRetryBiometricButton;

  /// No description provided for @appLockBiometricEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric sign in?'**
  String get appLockBiometricEnableTitle;

  /// No description provided for @appLockBiometricEnableDescription.
  ///
  /// In en, this message translates to:
  /// **'Next time you can quickly confirm access with Face ID or your fingerprint.'**
  String get appLockBiometricEnableDescription;

  /// No description provided for @appLockBiometricEnableButton.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get appLockBiometricEnableButton;

  /// No description provided for @appLockBiometricSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get appLockBiometricSkipButton;

  /// No description provided for @appLockBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric confirmation failed. Try again or switch to PIN.'**
  String get appLockBiometricFailed;

  /// No description provided for @appLockBiometricFallback.
  ///
  /// In en, this message translates to:
  /// **'Biometric access is temporarily unavailable. Enter your PIN.'**
  String get appLockBiometricFallback;

  /// No description provided for @profileIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile is incomplete'**
  String get profileIncompleteTitle;

  /// No description provided for @profileIncompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill in your first and last name to unlock all FlyFy features'**
  String get profileIncompleteDescription;

  /// No description provided for @fillNowButton.
  ///
  /// In en, this message translates to:
  /// **'Fill now'**
  String get fillNowButton;

  /// No description provided for @appLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageTitle;

  /// No description provided for @saveProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveProfileButton;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get profileSaveFailed;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get bioLabel;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get lastNameRequired;

  /// No description provided for @profileRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileRequiredTitle;

  /// No description provided for @profileRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'To continue, enter your first and last name in your profile. This helps reduce fake accounts and increases trust between users.'**
  String get profileRequiredDescription;

  /// No description provided for @laterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterButton;

  /// No description provided for @detectLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Detect from location'**
  String get detectLocationButton;

  /// No description provided for @useDetectedLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Use detected location?'**
  String get useDetectedLocationTitle;

  /// No description provided for @useDetectedLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'We detected your location as: {location}. Use it for your profile?'**
  String useDetectedLocationDescription(Object location);

  /// No description provided for @locationDetectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to detect location'**
  String get locationDetectFailed;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled on this device'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was not granted'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Please enable it in device settings'**
  String get locationPermissionDeniedForever;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @useButton.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useButton;

  /// No description provided for @activitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesTitle;

  /// No description provided for @activitiesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load activities'**
  String get activitiesLoadFailed;

  /// No description provided for @noActivitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get noActivitiesYet;

  /// No description provided for @activitiesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'New activities will appear here'**
  String get activitiesWillAppearHere;

  /// No description provided for @activityDetailsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Activity details page is coming soon'**
  String get activityDetailsComingSoon;

  /// No description provided for @detailsButton.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get fromLabel;

  /// No description provided for @activityStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get activityStatusDraft;

  /// No description provided for @activityStatusReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get activityStatusReviewRequired;

  /// No description provided for @activityStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get activityStatusPublished;

  /// No description provided for @activityStatusEnrollmentOpen.
  ///
  /// In en, this message translates to:
  /// **'Open for registration'**
  String get activityStatusEnrollmentOpen;

  /// No description provided for @activityStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get activityStatusFull;

  /// No description provided for @activityStatusStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get activityStatusStarted;

  /// No description provided for @activityStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get activityStatusCompleted;

  /// No description provided for @activityStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get activityStatusCancelled;

  /// No description provided for @activityStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get activityStatusArchived;

  /// No description provided for @activityFormatOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get activityFormatOffline;

  /// No description provided for @activityFormatOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get activityFormatOnline;

  /// No description provided for @activityFormatHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get activityFormatHybrid;

  /// No description provided for @activityFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get activityFormatLabel;

  /// No description provided for @activityDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityDetailsTitle;

  /// No description provided for @activityDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load activity'**
  String get activityDetailsLoadFailed;

  /// No description provided for @activityNotFound.
  ///
  /// In en, this message translates to:
  /// **'Activity not found'**
  String get activityNotFound;

  /// No description provided for @activityAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get activityAboutSection;

  /// No description provided for @activityInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get activityInfoSection;

  /// No description provided for @activityTagsSection.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get activityTagsSection;

  /// No description provided for @activityAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Access and safety'**
  String get activityAccessSection;

  /// No description provided for @activitySensitiveDetailsProtected.
  ///
  /// In en, this message translates to:
  /// **'The exact location, online meeting link, and sensitive details are available only after joining or being approved.'**
  String get activitySensitiveDetailsProtected;

  /// No description provided for @activitySensitiveDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'This is done for the safety of participants and organizers.'**
  String get activitySensitiveDetailsHint;

  /// No description provided for @activityDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get activityDateAndTime;

  /// No description provided for @activityCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get activityCategory;

  /// No description provided for @activityLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get activityLanguage;

  /// No description provided for @activityCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get activityCapacity;

  /// No description provided for @activityPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get activityPrice;

  /// No description provided for @activityLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get activityLocation;

  /// No description provided for @activityUnlimitedCapacity.
  ///
  /// In en, this message translates to:
  /// **'Number of participants is unlimited'**
  String get activityUnlimitedCapacity;

  /// No description provided for @activityLimitedCapacity.
  ///
  /// In en, this message translates to:
  /// **'Limited number of places'**
  String get activityLimitedCapacity;

  /// No description provided for @activityJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get activityJoinButton;

  /// No description provided for @activityLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get activityLeaveButton;

  /// No description provided for @activityLeaveInlineButton.
  ///
  /// In en, this message translates to:
  /// **'Leave Activity'**
  String get activityLeaveInlineButton;

  /// No description provided for @activityCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel activity'**
  String get activityCancelButton;

  /// No description provided for @activityCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this activity?'**
  String get activityCancelConfirmTitle;

  /// No description provided for @activityCancelConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'Participants will see that the activity was cancelled. Add a reason so they understand what happened.'**
  String get activityCancelConfirmDescription;

  /// No description provided for @activityCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get activityCancelReasonLabel;

  /// No description provided for @activityCancelReasonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: host is sick or the venue changed'**
  String get activityCancelReasonPlaceholder;

  /// No description provided for @activityCancelReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a cancellation reason'**
  String get activityCancelReasonRequired;

  /// No description provided for @activityCancelKeepButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get activityCancelKeepButton;

  /// No description provided for @activityCancelConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get activityCancelConfirmButton;

  /// No description provided for @activityJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'You joined the activity'**
  String get activityJoinSuccess;

  /// No description provided for @activityLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'You left the activity'**
  String get activityLeaveSuccess;

  /// No description provided for @activityCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity cancelled'**
  String get activityCancelSuccess;

  /// No description provided for @activityJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to join the activity'**
  String get activityJoinFailed;

  /// No description provided for @activityJoinAlreadyJoined.
  ///
  /// In en, this message translates to:
  /// **'You have already joined this activity'**
  String get activityJoinAlreadyJoined;

  /// No description provided for @activityJoinScheduleConflict.
  ///
  /// In en, this message translates to:
  /// **'You cannot join because you already have another activity at an overlapping time'**
  String get activityJoinScheduleConflict;

  /// No description provided for @activityLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave the activity'**
  String get activityLeaveFailed;

  /// No description provided for @activityCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel the activity'**
  String get activityCancelFailed;

  /// No description provided for @activityCancelAlreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'This activity is already cancelled'**
  String get activityCancelAlreadyCancelled;

  /// No description provided for @activityCancelNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This activity can no longer be cancelled'**
  String get activityCancelNotAllowed;

  /// No description provided for @activityGoingTitle.
  ///
  /// In en, this message translates to:
  /// **'Going ({count})'**
  String activityGoingTitle(int count);

  /// No description provided for @activityDetailsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get activityDetailsViewAll;

  /// No description provided for @activityDetailsLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get activityDetailsLinkCopied;

  /// No description provided for @activityDetailsHostedBadge.
  ///
  /// In en, this message translates to:
  /// **'Hosted by you'**
  String get activityDetailsHostedBadge;

  /// No description provided for @activityDetailsJoinedBadge.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get activityDetailsJoinedBadge;

  /// No description provided for @activityDetailsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get activityDetailsTotalLabel;

  /// No description provided for @activityDetailsChatButton.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get activityDetailsChatButton;

  /// No description provided for @activityDetailsHostFallbackName.
  ///
  /// In en, this message translates to:
  /// **'FlyFy Host'**
  String get activityDetailsHostFallbackName;

  /// No description provided for @activityPaymentScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'FLYFY CHECKOUT'**
  String get activityPaymentScreenTitle;

  /// No description provided for @activityPaymentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Summary'**
  String get activityPaymentSummaryTitle;

  /// No description provided for @activityPaymentBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Breakdown'**
  String get activityPaymentBreakdownTitle;

  /// No description provided for @activityPaymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get activityPaymentMethodTitle;

  /// No description provided for @activityPaymentHostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {host}'**
  String activityPaymentHostedBy(Object host);

  /// No description provided for @activityPaymentAdmissionLabel.
  ///
  /// In en, this message translates to:
  /// **'1x Activity Access'**
  String get activityPaymentAdmissionLabel;

  /// No description provided for @activityPaymentServiceFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get activityPaymentServiceFeeLabel;

  /// No description provided for @activityPaymentSavedCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved Card'**
  String get activityPaymentSavedCardLabel;

  /// No description provided for @activityPaymentCardHolderFallback.
  ///
  /// In en, this message translates to:
  /// **'FlyFy Member'**
  String get activityPaymentCardHolderFallback;

  /// No description provided for @activityPaymentApplePayLabel.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get activityPaymentApplePayLabel;

  /// No description provided for @activityPaymentGooglePayLabel.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get activityPaymentGooglePayLabel;

  /// No description provided for @activityPaymentConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay {amount}'**
  String activityPaymentConfirmButton(Object amount);

  /// No description provided for @activityPaymentSecureNote.
  ///
  /// In en, this message translates to:
  /// **'Secure 256-bit SSL encrypted payment'**
  String get activityPaymentSecureNote;

  /// No description provided for @activityPaymentPayButton.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get activityPaymentPayButton;

  /// No description provided for @activityPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as paid'**
  String get activityPaymentSuccess;

  /// No description provided for @activityPaymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get activityPaymentStatusLabel;

  /// No description provided for @activityPaymentPaidValue.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get activityPaymentPaidValue;

  /// No description provided for @activityParticipantFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get activityParticipantFallbackName;

  /// No description provided for @activityParticipantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get activityParticipantsEmpty;

  /// No description provided for @activityParticipantsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load participants right now'**
  String get activityParticipantsLoadFailed;

  /// No description provided for @activityPrivateJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Activity'**
  String get activityPrivateJoinTitle;

  /// No description provided for @activityPrivateJoinDescription.
  ///
  /// In en, this message translates to:
  /// **'This activity is curated for a select group. Please enter the invitation password to join.'**
  String get activityPrivateJoinDescription;

  /// No description provided for @activityPrivateJoinPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Password'**
  String get activityPrivateJoinPasswordLabel;

  /// No description provided for @activityPrivateJoinPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter access password'**
  String get activityPrivateJoinPasswordPlaceholder;

  /// No description provided for @activityPrivateJoinPasswordValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a password from 4 to 64 characters'**
  String get activityPrivateJoinPasswordValidation;

  /// No description provided for @activityPrivateJoinInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Try again.'**
  String get activityPrivateJoinInvalidPassword;

  /// No description provided for @activityPrivateJoinSubmit.
  ///
  /// In en, this message translates to:
  /// **'Verify & Join'**
  String get activityPrivateJoinSubmit;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'FlyFy'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Travel, discover activities, and explore new experiences'**
  String get homeSubtitle;

  /// No description provided for @servicesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesSectionTitle;

  /// No description provided for @homeToursTitle.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get homeToursTitle;

  /// No description provided for @homeToursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose interesting routes and trips'**
  String get homeToursSubtitle;

  /// No description provided for @homeGuidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get homeGuidesTitle;

  /// No description provided for @homeGuidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find local guides and experts'**
  String get homeGuidesSubtitle;

  /// No description provided for @homeHotelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get homeHotelsTitle;

  /// No description provided for @homeHotelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book accommodation quickly and conveniently'**
  String get homeHotelsSubtitle;

  /// No description provided for @homeTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get homeTransportTitle;

  /// No description provided for @homeTransportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your trips in advance'**
  String get homeTransportSubtitle;

  /// No description provided for @homeCurrentLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get homeCurrentLocationLabel;

  /// No description provided for @homeExploringLocation.
  ///
  /// In en, this message translates to:
  /// **'{location}'**
  String homeExploringLocation(Object location);

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations, stays or cars'**
  String get homeSearchHint;

  /// No description provided for @homeTopDestinations.
  ///
  /// In en, this message translates to:
  /// **'Top Destinations'**
  String get homeTopDestinations;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeRecommendedBlogs.
  ///
  /// In en, this message translates to:
  /// **'Recommended Blogs'**
  String get homeRecommendedBlogs;

  /// No description provided for @homeEditorialBadge.
  ///
  /// In en, this message translates to:
  /// **'Editorial'**
  String get homeEditorialBadge;

  /// No description provided for @homeStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems of Central Asia'**
  String get homeStoryTitle;

  /// No description provided for @homeStoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover secret trails and cultural corners across Almaty\'s adventurous side.'**
  String get homeStoryDescription;

  /// No description provided for @homeReadStory.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get homeReadStory;

  /// No description provided for @homeFeaturedStays.
  ///
  /// In en, this message translates to:
  /// **'Featured Stays'**
  String get homeFeaturedStays;

  /// No description provided for @homeCarRentals.
  ///
  /// In en, this message translates to:
  /// **'Car Rentals'**
  String get homeCarRentals;

  /// No description provided for @homeRecommendedActivities.
  ///
  /// In en, this message translates to:
  /// **'Recommended Activities'**
  String get homeRecommendedActivities;

  /// No description provided for @homeFilterButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get homeFilterButton;

  /// No description provided for @homeMoreButton.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get homeMoreButton;

  /// No description provided for @homeDestinationCharynTitle.
  ///
  /// In en, this message translates to:
  /// **'Charyn Canyon'**
  String get homeDestinationCharynTitle;

  /// No description provided for @homeDestinationCharynSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nature & Adventure'**
  String get homeDestinationCharynSubtitle;

  /// No description provided for @homeDestinationLakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Big Almaty Lake'**
  String get homeDestinationLakeTitle;

  /// No description provided for @homeDestinationLakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scenic Views'**
  String get homeDestinationLakeSubtitle;

  /// No description provided for @homeDestinationKolsaiTitle.
  ///
  /// In en, this message translates to:
  /// **'Kolsai Lakes'**
  String get homeDestinationKolsaiTitle;

  /// No description provided for @homeDestinationKolsaiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mountain Escape'**
  String get homeDestinationKolsaiSubtitle;

  /// No description provided for @homeDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String homeDurationHours(Object hours);

  /// No description provided for @homeBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get homeBookNow;

  /// No description provided for @homeNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavHome;

  /// No description provided for @homeNavQr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get homeNavQr;

  /// No description provided for @homeNavMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get homeNavMap;

  /// No description provided for @homeNavChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get homeNavChats;

  /// No description provided for @homeNavMy.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get homeNavMy;

  /// No description provided for @activitiesEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesEntryTitle;

  /// No description provided for @activitiesEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find offline and online events you can join'**
  String get activitiesEntrySubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @createActivityFab.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createActivityFab;

  /// No description provided for @createActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Activity'**
  String get createActivityTitle;

  /// No description provided for @createActivitySubmit.
  ///
  /// In en, this message translates to:
  /// **'Create Activity'**
  String get createActivitySubmit;

  /// No description provided for @createActivitySuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity created successfully'**
  String get createActivitySuccess;

  /// No description provided for @createActivityFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create activity'**
  String get createActivityFailed;

  /// No description provided for @createStepBasic.
  ///
  /// In en, this message translates to:
  /// **'Main Info'**
  String get createStepBasic;

  /// No description provided for @createStepDetailsLogistics.
  ///
  /// In en, this message translates to:
  /// **'Details & Logistics'**
  String get createStepDetailsLogistics;

  /// No description provided for @createStepRulesPricing.
  ///
  /// In en, this message translates to:
  /// **'Rules & Pricing'**
  String get createStepRulesPricing;

  /// No description provided for @createStepSchedule.
  ///
  /// In en, this message translates to:
  /// **'Format & Schedule'**
  String get createStepSchedule;

  /// No description provided for @createStepParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get createStepParticipation;

  /// No description provided for @createStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get createStepLocation;

  /// No description provided for @createStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String createStepCounter(Object current, Object total);

  /// No description provided for @createHelpAction.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get createHelpAction;

  /// No description provided for @createStepNext.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get createStepNext;

  /// No description provided for @createStepBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get createStepBack;

  /// No description provided for @createCoverSection.
  ///
  /// In en, this message translates to:
  /// **'Upload Activity Cover'**
  String get createCoverSection;

  /// No description provided for @createCoverUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload High-Res Image'**
  String get createCoverUploadTitle;

  /// No description provided for @createCoverChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get createCoverChangeAction;

  /// No description provided for @createCoverUploadHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or WEBP. Recommended 1600x900px, max 20MB'**
  String get createCoverUploadHint;

  /// No description provided for @createCoverUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload the cover image. Please try again.'**
  String get createCoverUploadFailed;

  /// No description provided for @createCoverUploadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The image is too large. Maximum size is 20MB.'**
  String get createCoverUploadTooLarge;

  /// No description provided for @createCoverUploadUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format. Use JPG, PNG or WEBP.'**
  String get createCoverUploadUnsupportedFormat;

  /// No description provided for @createCoverUploadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Wait until the cover image upload finishes.'**
  String get createCoverUploadInProgress;

  /// No description provided for @createCoverUploadRetryRequired.
  ///
  /// In en, this message translates to:
  /// **'Upload the cover image again before continuing.'**
  String get createCoverUploadRetryRequired;

  /// No description provided for @createBasicSection.
  ///
  /// In en, this message translates to:
  /// **'BASIC INFORMATION'**
  String get createBasicSection;

  /// No description provided for @createTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity Title'**
  String get createTitleLabel;

  /// No description provided for @createTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunset Yoga by the Pier'**
  String get createTitleHint;

  /// No description provided for @createTitleValidation.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 3 characters'**
  String get createTitleValidation;

  /// No description provided for @createDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createDescriptionLabel;

  /// No description provided for @createDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about the activity...'**
  String get createDescriptionHint;

  /// No description provided for @createDescriptionValidation.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get createDescriptionValidation;

  /// No description provided for @createCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get createCategoryLabel;

  /// No description provided for @createCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get createCategoryHint;

  /// No description provided for @createCategoryValidation.
  ///
  /// In en, this message translates to:
  /// **'Please choose a category'**
  String get createCategoryValidation;

  /// No description provided for @createCategoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading categories'**
  String get createCategoryLoading;

  /// No description provided for @createCategoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get createCategoryLoadFailed;

  /// No description provided for @createCategoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get createCategoryEmpty;

  /// No description provided for @createCategoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get createCategoryRetry;

  /// No description provided for @createCategoryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Category'**
  String get createCategoryPickerTitle;

  /// No description provided for @createCategoryApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Category'**
  String get createCategoryApply;

  /// No description provided for @createTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get createTagsLabel;

  /// No description provided for @createTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated: running, morning, park'**
  String get createTagsHint;

  /// No description provided for @createEventFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Format'**
  String get createEventFormatLabel;

  /// No description provided for @createFormatSection.
  ///
  /// In en, this message translates to:
  /// **'FORMAT'**
  String get createFormatSection;

  /// No description provided for @createScheduleSection.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get createScheduleSection;

  /// No description provided for @createDatePartLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get createDatePartLabel;

  /// No description provided for @createTimePartLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get createTimePartLabel;

  /// No description provided for @createStartAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get createStartAtLabel;

  /// No description provided for @createEndAtLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get createEndAtLabel;

  /// No description provided for @createStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get createStartDateLabel;

  /// No description provided for @createEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get createEndDateLabel;

  /// No description provided for @createStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get createStartTimeLabel;

  /// No description provided for @createEndTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get createEndTimeLabel;

  /// No description provided for @createScheduleInputValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid date and time'**
  String get createScheduleInputValidation;

  /// No description provided for @createRegistrationDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration deadline'**
  String get createRegistrationDeadlineLabel;

  /// No description provided for @createEndDateValidation.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get createEndDateValidation;

  /// No description provided for @createStartAtTooSoonValidation.
  ///
  /// In en, this message translates to:
  /// **'Start time must be at least 1 hour from now'**
  String get createStartAtTooSoonValidation;

  /// No description provided for @createRegistrationDeadlineValidation.
  ///
  /// In en, this message translates to:
  /// **'Registration deadline must be before the start time'**
  String get createRegistrationDeadlineValidation;

  /// No description provided for @createRegistrationAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Registration closes automatically 1 hour before the activity starts'**
  String get createRegistrationAutoHint;

  /// No description provided for @createSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get createSaveDraft;

  /// No description provided for @createAndPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get createAndPublish;

  /// No description provided for @createPublishActivityCta.
  ///
  /// In en, this message translates to:
  /// **'Publish Activity'**
  String get createPublishActivityCta;

  /// No description provided for @createLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY LANGUAGE'**
  String get createLanguageSection;

  /// No description provided for @createVisibilitySection.
  ///
  /// In en, this message translates to:
  /// **'VISIBILITY'**
  String get createVisibilitySection;

  /// No description provided for @createVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get createVisibilityPublic;

  /// No description provided for @createVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get createVisibilityPrivate;

  /// No description provided for @createVisibilityUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Unlisted'**
  String get createVisibilityUnlisted;

  /// No description provided for @createActivityPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Privacy'**
  String get createActivityPrivacyTitle;

  /// No description provided for @createVisibilityPrivateWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Private with password'**
  String get createVisibilityPrivateWithPassword;

  /// No description provided for @createVisibilityByLink.
  ///
  /// In en, this message translates to:
  /// **'By link'**
  String get createVisibilityByLink;

  /// No description provided for @createVisibilityPublicDescription.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone on FlyFy'**
  String get createVisibilityPublicDescription;

  /// No description provided for @createVisibilityPrivateDescription.
  ///
  /// In en, this message translates to:
  /// **'Only people with the code can see'**
  String get createVisibilityPrivateDescription;

  /// No description provided for @createVisibilityUnlistedDescription.
  ///
  /// In en, this message translates to:
  /// **'Accessible only via invite link'**
  String get createVisibilityUnlistedDescription;

  /// No description provided for @createVisibilityPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose privacy'**
  String get createVisibilityPickerTitle;

  /// No description provided for @createVisibilityApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get createVisibilityApply;

  /// No description provided for @createVisibilityPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity password'**
  String get createVisibilityPasswordLabel;

  /// No description provided for @createVisibilityPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get createVisibilityPasswordPlaceholder;

  /// No description provided for @createVisibilityPasswordValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a password from 4 to 64 characters'**
  String get createVisibilityPasswordValidation;

  /// No description provided for @createVisibilityPasswordEditHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the current password'**
  String get createVisibilityPasswordEditHint;

  /// No description provided for @createJoinModeSection.
  ///
  /// In en, this message translates to:
  /// **'JOIN MODE'**
  String get createJoinModeSection;

  /// No description provided for @createJoinModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto approve'**
  String get createJoinModeAuto;

  /// No description provided for @createJoinModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual approve'**
  String get createJoinModeManual;

  /// No description provided for @createJoinApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Approval'**
  String get createJoinApprovalTitle;

  /// No description provided for @createJoinModeAutomaticShort.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get createJoinModeAutomaticShort;

  /// No description provided for @createJoinModeManualShort.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get createJoinModeManualShort;

  /// No description provided for @createJoinModePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose approval mode'**
  String get createJoinModePickerTitle;

  /// No description provided for @createJoinModeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get createJoinModeApply;

  /// No description provided for @createCapacitySection.
  ///
  /// In en, this message translates to:
  /// **'CAPACITY'**
  String get createCapacitySection;

  /// No description provided for @createCapacityUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get createCapacityUnlimited;

  /// No description provided for @createCapacityLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get createCapacityLimited;

  /// No description provided for @createMinParticipantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get createMinParticipantsLabel;

  /// No description provided for @createMaxParticipantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get createMaxParticipantsLabel;

  /// No description provided for @createParticipantLimitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participant Limits'**
  String get createParticipantLimitsTitle;

  /// No description provided for @createUnlimitedParticipantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlimited participants'**
  String get createUnlimitedParticipantsLabel;

  /// No description provided for @createParticipantsMinShort.
  ///
  /// In en, this message translates to:
  /// **'MIN'**
  String get createParticipantsMinShort;

  /// No description provided for @createParticipantsMaxShort.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get createParticipantsMaxShort;

  /// No description provided for @createNoLimitPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get createNoLimitPlaceholder;

  /// No description provided for @createMaxParticipantsValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid maximum number'**
  String get createMaxParticipantsValidation;

  /// No description provided for @createMinExceedsMaxValidation.
  ///
  /// In en, this message translates to:
  /// **'Minimum cannot exceed maximum'**
  String get createMinExceedsMaxValidation;

  /// No description provided for @createPriceSection.
  ///
  /// In en, this message translates to:
  /// **'PRICING'**
  String get createPriceSection;

  /// No description provided for @createPriceFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get createPriceFree;

  /// No description provided for @createPricePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get createPricePaid;

  /// No description provided for @createPriceDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get createPriceDeposit;

  /// No description provided for @createPricingModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing Model'**
  String get createPricingModelTitle;

  /// No description provided for @createPriceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get createPriceAmountLabel;

  /// No description provided for @createPriceAmountOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Price amount (optional)'**
  String get createPriceAmountOptionalLabel;

  /// No description provided for @createPriceAmountPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'\$ 0.00'**
  String get createPriceAmountPlaceholder;

  /// No description provided for @createCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get createCurrencyLabel;

  /// No description provided for @createPricePerPersonHint.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get createPricePerPersonHint;

  /// No description provided for @createPriceValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get createPriceValidation;

  /// No description provided for @createOnlineSection.
  ///
  /// In en, this message translates to:
  /// **'ONLINE ACCESS'**
  String get createOnlineSection;

  /// No description provided for @createOnlineAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Share the meeting link participants should use to join online'**
  String get createOnlineAccessHint;

  /// No description provided for @createMeetingUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting link'**
  String get createMeetingUrlLabel;

  /// No description provided for @createMeetingUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://zoom.us/...'**
  String get createMeetingUrlHint;

  /// No description provided for @createMeetingUrlValidation.
  ///
  /// In en, this message translates to:
  /// **'Please provide a meeting link'**
  String get createMeetingUrlValidation;

  /// No description provided for @createMeetingPointLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting point / Location'**
  String get createMeetingPointLocationLabel;

  /// No description provided for @createMeetingPointTitle.
  ///
  /// In en, this message translates to:
  /// **'MEETING POINT'**
  String get createMeetingPointTitle;

  /// No description provided for @createVenueOrAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter venue or address'**
  String get createVenueOrAddressHint;

  /// No description provided for @createMapLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Map Link'**
  String get createMapLinkLabel;

  /// No description provided for @createMapLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste Maps URL'**
  String get createMapLinkHint;

  /// No description provided for @createOfflineSection.
  ///
  /// In en, this message translates to:
  /// **'VENUE'**
  String get createOfflineSection;

  /// No description provided for @createLocationPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Add a city or address so participants know where to meet'**
  String get createLocationPreviewHint;

  /// No description provided for @createCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get createCountryLabel;

  /// No description provided for @createCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get createCityLabel;

  /// No description provided for @createCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Almaty'**
  String get createCityHint;

  /// No description provided for @createAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get createAddressLabel;

  /// No description provided for @createAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, building, etc.'**
  String get createAddressHint;

  /// No description provided for @createMapTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to pin the meeting point'**
  String get createMapTapHint;

  /// No description provided for @createMapResolvingHint.
  ///
  /// In en, this message translates to:
  /// **'Looking up the address...'**
  String get createMapResolvingHint;

  /// No description provided for @createMapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Maps preview is available in configured iOS and Android builds'**
  String get createMapUnavailable;

  /// No description provided for @createLocationValidation.
  ///
  /// In en, this message translates to:
  /// **'Please specify a city or address'**
  String get createLocationValidation;

  /// No description provided for @editActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity'**
  String get editActivityTitle;

  /// No description provided for @editActivityButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editActivityButton;

  /// No description provided for @editActivitySubmit.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editActivitySubmit;

  /// No description provided for @editActivitySuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity updated successfully'**
  String get editActivitySuccess;

  /// No description provided for @editActivityFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update activity'**
  String get editActivityFailed;

  /// No description provided for @activityPublishButton.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get activityPublishButton;

  /// No description provided for @activityPublishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity published successfully'**
  String get activityPublishSuccess;

  /// No description provided for @activityPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish activity'**
  String get activityPublishFailed;

  /// No description provided for @editFormatLocked.
  ///
  /// In en, this message translates to:
  /// **'Format cannot be changed after creation'**
  String get editFormatLocked;

  /// No description provided for @editLocationLocked.
  ///
  /// In en, this message translates to:
  /// **'Location cannot be changed after publication'**
  String get editLocationLocked;

  /// No description provided for @editPriceRestrictionHint.
  ///
  /// In en, this message translates to:
  /// **'Price cannot be changed if participants have already joined'**
  String get editPriceRestrictionHint;

  /// No description provided for @myActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Activities'**
  String get myActivitiesTitle;

  /// No description provided for @myActivitiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any activities yet'**
  String get myActivitiesEmpty;

  /// No description provided for @myActivitiesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first activity and it will appear here'**
  String get myActivitiesEmptyHint;

  /// No description provided for @myActivitiesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your activities'**
  String get myActivitiesLoadFailed;

  /// No description provided for @myActivitiesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get myActivitiesFilterAll;

  /// No description provided for @myActivitiesLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String myActivitiesLastUpdated(Object date);

  /// No description provided for @myActivitiesContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get myActivitiesContinueButton;

  /// No description provided for @myActivitiesAttendedTab.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get myActivitiesAttendedTab;

  /// No description provided for @myActivitiesAttendedEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t attended any activities yet'**
  String get myActivitiesAttendedEmpty;

  /// No description provided for @myActivitiesAttendedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Activities you join will appear here'**
  String get myActivitiesAttendedEmptyHint;

  /// No description provided for @myActivitiesAttendedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load attended activities'**
  String get myActivitiesAttendedLoadFailed;

  /// No description provided for @myActivitiesFilterButton.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get myActivitiesFilterButton;

  /// No description provided for @myActivitiesFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get myActivitiesFilterTitle;

  /// No description provided for @myActivitiesFilterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get myActivitiesFilterDateRange;

  /// No description provided for @myActivitiesFilterStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get myActivitiesFilterStartDate;

  /// No description provided for @myActivitiesFilterEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get myActivitiesFilterEndDate;

  /// No description provided for @myActivitiesFilterDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'dd.mm.yyyy'**
  String get myActivitiesFilterDatePlaceholder;

  /// No description provided for @myActivitiesFilterDateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the date manually in dd.mm.yyyy format'**
  String get myActivitiesFilterDateHint;

  /// No description provided for @myActivitiesFilterInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date'**
  String get myActivitiesFilterInvalidDate;

  /// No description provided for @myActivitiesFilterInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'The end date cannot be earlier than the start date'**
  String get myActivitiesFilterInvalidRange;

  /// No description provided for @myActivitiesFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get myActivitiesFilterStatus;

  /// No description provided for @myActivitiesFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get myActivitiesFilterClear;

  /// No description provided for @myActivitiesFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get myActivitiesFilterApply;

  /// No description provided for @myActivitiesRecreateButton.
  ///
  /// In en, this message translates to:
  /// **'Recreate'**
  String get myActivitiesRecreateButton;

  /// No description provided for @myActivitiesRestrictedButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Restricted'**
  String get myActivitiesRestrictedButton;

  /// No description provided for @myActivitiesOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Open Activity'**
  String get myActivitiesOpenButton;

  /// No description provided for @myActivitiesRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get myActivitiesRetryButton;

  /// No description provided for @myActivitiesPriceNoteFree.
  ///
  /// In en, this message translates to:
  /// **'no fee'**
  String get myActivitiesPriceNoteFree;

  /// No description provided for @activityPerPerson.
  ///
  /// In en, this message translates to:
  /// **'/ person'**
  String get activityPerPerson;

  /// No description provided for @activitySpotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} Spots Left'**
  String activitySpotsLeft(Object count);

  /// No description provided for @activityUnlimitedSpots.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get activityUnlimitedSpots;

  /// No description provided for @activityMeetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting Point'**
  String get activityMeetingPoint;

  /// No description provided for @activityGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get activityGetDirections;

  /// No description provided for @activityHostSection.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get activityHostSection;

  /// No description provided for @activityTotalCapacity.
  ///
  /// In en, this message translates to:
  /// **'Total Capacity'**
  String get activityTotalCapacity;

  /// No description provided for @activityPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get activityPricing;

  /// No description provided for @activityPeopleMax.
  ///
  /// In en, this message translates to:
  /// **'{count} People Max'**
  String activityPeopleMax(Object count);

  /// No description provided for @activityJoinActivity.
  ///
  /// In en, this message translates to:
  /// **'Join Activity'**
  String get activityJoinActivity;

  /// No description provided for @activitiesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search activities, hosts, or cities'**
  String get activitiesSearchHint;

  /// No description provided for @activitiesFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get activitiesFilterCategory;

  /// No description provided for @activitiesFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get activitiesFilterDate;

  /// No description provided for @activitiesFilterPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get activitiesFilterPricing;

  /// No description provided for @activitiesFilterVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get activitiesFilterVisibility;

  /// No description provided for @activitiesDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Activities'**
  String get activitiesDiscoverTitle;

  /// No description provided for @activitiesFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities match these filters'**
  String get activitiesFilteredEmptyTitle;

  /// No description provided for @activitiesFilteredEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try widening the category, date range, or pricing filters'**
  String get activitiesFilteredEmptySubtitle;

  /// No description provided for @activitiesResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No activities} =1{1 activity} other{{count} activities}}'**
  String activitiesResultsCount(num count);

  /// No description provided for @activitiesFiltersCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get activitiesFiltersCategoriesTitle;

  /// No description provided for @activitiesFiltersSelectedCategories.
  ///
  /// In en, this message translates to:
  /// **'Selected Categories'**
  String get activitiesFiltersSelectedCategories;

  /// No description provided for @activitiesShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show {count, plural, =0{0 activities} =1{1 activity} other{{count} activities}}'**
  String activitiesShowResults(num count);

  /// No description provided for @activitiesAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get activitiesAllCategories;

  /// No description provided for @activitiesFiltersPriceRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get activitiesFiltersPriceRangeTitle;

  /// No description provided for @activitiesFiltersVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get activitiesFiltersVisibilityTitle;

  /// No description provided for @activitiesFilterMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get activitiesFilterMinPrice;

  /// No description provided for @activitiesFilterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get activitiesFilterMaxPrice;

  /// No description provided for @activitiesDatePresetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get activitiesDatePresetToday;

  /// No description provided for @activitiesDatePresetTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get activitiesDatePresetTomorrow;

  /// No description provided for @activitiesDatePresetThisWeekend.
  ///
  /// In en, this message translates to:
  /// **'This Weekend'**
  String get activitiesDatePresetThisWeekend;

  /// No description provided for @activitiesDatePresetThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get activitiesDatePresetThisWeek;

  /// No description provided for @activitiesDatePresetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get activitiesDatePresetThisMonth;

  /// No description provided for @activityViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get activityViewDetails;

  /// No description provided for @activityJoinSession.
  ///
  /// In en, this message translates to:
  /// **'Join Session'**
  String get activityJoinSession;

  /// No description provided for @activityGetLink.
  ///
  /// In en, this message translates to:
  /// **'Get Link'**
  String get activityGetLink;

  /// No description provided for @activityAttendanceQrButton.
  ///
  /// In en, this message translates to:
  /// **'Attendance QR'**
  String get activityAttendanceQrButton;

  /// No description provided for @activityAttendanceQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity QR'**
  String get activityAttendanceQrTitle;

  /// No description provided for @activityAttendanceQrFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityAttendanceQrFallbackTitle;

  /// No description provided for @activityAttendanceQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show this QR to participants so they can confirm arrival in the app.'**
  String get activityAttendanceQrSubtitle;

  /// No description provided for @activityAttendanceQrHelper.
  ///
  /// In en, this message translates to:
  /// **'The QR refreshes automatically. Participants should scan the current code using the QR button in the bottom bar.'**
  String get activityAttendanceQrHelper;

  /// No description provided for @activityAttendanceQrLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the activity QR'**
  String get activityAttendanceQrLoadFailed;

  /// No description provided for @activityAttendanceQrRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'The code refreshes automatically to reduce duplicates and screenshot reuse.'**
  String get activityAttendanceQrRefreshHint;

  /// No description provided for @activityAttendanceQrRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing QR…'**
  String get activityAttendanceQrRefreshing;

  /// No description provided for @activityAttendanceQrExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Refresh in {seconds}s'**
  String activityAttendanceQrExpiresIn(Object seconds);

  /// No description provided for @qrScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get qrScannerTitle;

  /// No description provided for @qrScannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the host QR to confirm that you arrived at the activity.'**
  String get qrScannerSubtitle;

  /// No description provided for @qrScannerReady.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code'**
  String get qrScannerReady;

  /// No description provided for @qrScannerInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This is not a FlyFy activity QR'**
  String get qrScannerInvalidCode;

  /// No description provided for @qrScannerSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Current session is unavailable. Reopen the screen and try again.'**
  String get qrScannerSessionUnavailable;

  /// No description provided for @qrScannerAlreadyQueued.
  ///
  /// In en, this message translates to:
  /// **'This check-in is already waiting to sync'**
  String get qrScannerAlreadyQueued;

  /// No description provided for @qrScannerQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'Check-in saved. It will sync when the connection is back.'**
  String get qrScannerQueuedOffline;

  /// No description provided for @qrScannerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Arrival confirmed'**
  String get qrScannerSuccess;

  /// No description provided for @qrScannerAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You are already checked in to this activity'**
  String get qrScannerAlreadyCheckedIn;

  /// No description provided for @qrScannerNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'You are not registered for this activity'**
  String get qrScannerNotRegistered;

  /// No description provided for @qrScannerNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Check-in is not available for this booking yet'**
  String get qrScannerNotEligible;

  /// No description provided for @qrScannerQrExpired.
  ///
  /// In en, this message translates to:
  /// **'This QR already expired. Ask the host to open a new one.'**
  String get qrScannerQrExpired;

  /// No description provided for @qrScannerHostNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'The host cannot scan their own QR'**
  String get qrScannerHostNotAllowed;

  /// No description provided for @qrScannerActivityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check-in is unavailable for this activity right now'**
  String get qrScannerActivityUnavailable;

  /// No description provided for @qrScannerCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable. Check camera permission and try again.'**
  String get qrScannerCameraUnavailable;

  /// No description provided for @qrScannerSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get qrScannerSyncNow;

  /// No description provided for @qrScannerScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get qrScannerScanAgain;

  /// No description provided for @qrScannerPendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending sync: {count}'**
  String qrScannerPendingCount(Object count);

  /// No description provided for @qrScannerNoPending.
  ///
  /// In en, this message translates to:
  /// **'No pending check-ins'**
  String get qrScannerNoPending;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
