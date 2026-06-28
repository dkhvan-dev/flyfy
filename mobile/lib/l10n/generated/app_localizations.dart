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
  /// **'Inflap'**
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

  /// No description provided for @welcomeToInflap.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Inflap'**
  String get welcomeToInflap;

  /// No description provided for @authByPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get authByPhone;

  /// No description provided for @authLoginTab.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginTab;

  /// No description provided for @authRegisterTab.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterTab;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get authLoginTitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authRegisterTitle;

  /// No description provided for @authIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname or email'**
  String get authIdentifierLabel;

  /// No description provided for @authIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'@nomad or traveler@example.com'**
  String get authIdentifierHint;

  /// No description provided for @authIdentifierRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname or email'**
  String get authIdentifierRequiredError;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'traveler@example.com'**
  String get authEmailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHint;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginAction;

  /// No description provided for @authRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterAction;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your details and try again.'**
  String get authLoginFailed;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start registration. Check your details and try again.'**
  String get authRegistrationFailed;

  /// No description provided for @authPasswordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatchError;

  /// No description provided for @authForgotPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordAction;

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover access'**
  String get passwordResetTitle;

  /// No description provided for @passwordResetRequestDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or nickname. If the account exists, we will send a code to the linked email.'**
  String get passwordResetRequestDescription;

  /// No description provided for @passwordResetVerifyDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from the email and set a new account password.'**
  String get passwordResetVerifyDescription;

  /// No description provided for @passwordResetIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or nickname'**
  String get passwordResetIdentifierLabel;

  /// No description provided for @passwordResetIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'@nomad or traveler@example.com'**
  String get passwordResetIdentifierHint;

  /// No description provided for @passwordResetIdentifierRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or nickname'**
  String get passwordResetIdentifierRequiredError;

  /// No description provided for @passwordResetCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get passwordResetCodeLabel;

  /// No description provided for @passwordResetCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get passwordResetCodeHint;

  /// No description provided for @passwordResetCodeRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get passwordResetCodeRequiredError;

  /// No description provided for @passwordResetNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordResetNewPasswordLabel;

  /// No description provided for @passwordResetConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get passwordResetConfirmPasswordLabel;

  /// No description provided for @passwordResetSendCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get passwordResetSendCodeAction;

  /// No description provided for @passwordResetResendCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get passwordResetResendCodeAction;

  /// No description provided for @passwordResetResendCodeCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String passwordResetResendCodeCountdown(String time);

  /// No description provided for @passwordResetSavePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get passwordResetSavePasswordAction;

  /// No description provided for @passwordResetBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get passwordResetBackToLogin;

  /// No description provided for @passwordResetStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the recovery code. Try again.'**
  String get passwordResetStartFailed;

  /// No description provided for @passwordResetVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the password. Check the code and try again.'**
  String get passwordResetVerifyFailed;

  /// No description provided for @passwordResetSentNotice.
  ///
  /// In en, this message translates to:
  /// **'If the account exists, the code was sent to the linked email.'**
  String get passwordResetSentNotice;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in with the new password.'**
  String get passwordResetSuccess;

  /// No description provided for @emailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailRequiredError;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalidError;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequiredError;

  /// No description provided for @passwordWeakError.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 8 characters, letters, and digits'**
  String get passwordWeakError;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

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

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @enterAuthCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we just sent to\n'**
  String get enterAuthCode;

  /// No description provided for @enterEmailAuthCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we just sent to\n'**
  String get enterEmailAuthCode;

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

  /// No description provided for @serviceExcursions.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get serviceExcursions;

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

  /// No description provided for @serviceTravelChecklist.
  ///
  /// In en, this message translates to:
  /// **'Travel checklist'**
  String get serviceTravelChecklist;

  /// No description provided for @travelChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip preparation'**
  String get travelChecklistTitle;

  /// No description provided for @travelChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **''**
  String get travelChecklistSubtitle;

  /// No description provided for @travelChecklistOptimizeRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize day route'**
  String get travelChecklistOptimizeRouteTitle;

  /// No description provided for @travelChecklistOptimizeRouteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order {count} stops by route time before you start the day.'**
  String travelChecklistOptimizeRouteSubtitle(Object count);

  /// No description provided for @travelChecklistOptimizeRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get travelChecklistOptimizeRouteButton;

  /// No description provided for @travelChecklistOptimizeRouteRetry.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get travelChecklistOptimizeRouteRetry;

  /// No description provided for @travelChecklistOptimizeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not optimize the route right now.'**
  String get travelChecklistOptimizeFailed;

  /// No description provided for @travelChecklistCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare for this trip'**
  String get travelChecklistCtaTitle;

  /// No description provided for @travelChecklistCtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Readiness, season and baggage rules'**
  String get travelChecklistCtaSubtitle;

  /// No description provided for @travelChecklistOpen.
  ///
  /// In en, this message translates to:
  /// **'Open checklist'**
  String get travelChecklistOpen;

  /// No description provided for @travelChecklistPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get travelChecklistPreviewAction;

  /// No description provided for @travelChecklistPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Book this excursion to save a personal checklist with progress, reminders, and your own items.'**
  String get travelChecklistPreviewMessage;

  /// No description provided for @travelChecklistPreviewDate.
  ///
  /// In en, this message translates to:
  /// **'Selected when booking'**
  String get travelChecklistPreviewDate;

  /// No description provided for @travelChecklistSampleTrip.
  ///
  /// In en, this message translates to:
  /// **'Tokyo · July sample'**
  String get travelChecklistSampleTrip;

  /// No description provided for @travelChecklistMissingContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a trip first'**
  String get travelChecklistMissingContextTitle;

  /// No description provided for @travelChecklistMissingContextMessage.
  ///
  /// In en, this message translates to:
  /// **'The checklist is calculated from destination, dates, transport, and activities. Open it from a booking, excursion, or activity so Inflap does not show unrelated advice.'**
  String get travelChecklistMissingContextMessage;

  /// No description provided for @travelChecklistMissingContextPrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Choose excursion'**
  String get travelChecklistMissingContextPrimaryAction;

  /// No description provided for @travelChecklistMissingContextSecondaryAction.
  ///
  /// In en, this message translates to:
  /// **'Open activities'**
  String get travelChecklistMissingContextSecondaryAction;

  /// No description provided for @travelChecklistQuickPrepTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick preparation'**
  String get travelChecklistQuickPrepTitle;

  /// No description provided for @travelChecklistQuickPrepMessage.
  ///
  /// In en, this message translates to:
  /// **'Create preparation without a booking: enter destination, dates, transport, and activities, and Inflap will build the checklist for this trip.'**
  String get travelChecklistQuickPrepMessage;

  /// No description provided for @travelChecklistQuickPrepCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get travelChecklistQuickPrepCountryCode;

  /// No description provided for @travelChecklistQuickPrepCountryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Turkey'**
  String get travelChecklistQuickPrepCountryCodeHint;

  /// No description provided for @travelChecklistQuickPrepCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get travelChecklistQuickPrepCity;

  /// No description provided for @travelChecklistQuickPrepCityHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Istanbul'**
  String get travelChecklistQuickPrepCityHint;

  /// No description provided for @travelChecklistQuickPrepStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get travelChecklistQuickPrepStartDate;

  /// No description provided for @travelChecklistQuickPrepEndDate.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get travelChecklistQuickPrepEndDate;

  /// No description provided for @travelChecklistQuickPrepTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'How you get there'**
  String get travelChecklistQuickPrepTransportTitle;

  /// No description provided for @travelChecklistQuickPrepActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'What you plan'**
  String get travelChecklistQuickPrepActivitiesTitle;

  /// No description provided for @travelChecklistQuickPrepWithChildren.
  ///
  /// In en, this message translates to:
  /// **'Traveling with children'**
  String get travelChecklistQuickPrepWithChildren;

  /// No description provided for @travelChecklistQuickPrepSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create preparation'**
  String get travelChecklistQuickPrepSubmit;

  /// No description provided for @travelChecklistQuickPrepDuplicateOpened.
  ///
  /// In en, this message translates to:
  /// **'You already have a preparation for this trip.'**
  String get travelChecklistQuickPrepDuplicateOpened;

  /// No description provided for @travelChecklistQuickPrepCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a country.'**
  String get travelChecklistQuickPrepCountryRequired;

  /// No description provided for @travelChecklistQuickPrepCountryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a country from the list or enter a clear country name.'**
  String get travelChecklistQuickPrepCountryInvalid;

  /// No description provided for @travelChecklistQuickPrepCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a city.'**
  String get travelChecklistQuickPrepCityRequired;

  /// No description provided for @travelChecklistQuickPrepAlternativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Or open a checklist from an existing flow'**
  String get travelChecklistQuickPrepAlternativeTitle;

  /// No description provided for @travelChecklistRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'My checklists'**
  String get travelChecklistRecentTitle;

  /// No description provided for @travelChecklistRecentMessage.
  ///
  /// In en, this message translates to:
  /// **'Recently created preparations appear here so you can reopen the same trip context.'**
  String get travelChecklistRecentMessage;

  /// No description provided for @travelChecklistRecentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No checklists yet'**
  String get travelChecklistRecentEmptyTitle;

  /// No description provided for @travelChecklistRecentEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a preparation with country, city, dates, transport, and activities. Your checklist will appear here afterwards.'**
  String get travelChecklistRecentEmptyMessage;

  /// No description provided for @travelChecklistFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get travelChecklistFilterAll;

  /// No description provided for @travelChecklistFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get travelChecklistFilterUpcoming;

  /// No description provided for @travelChecklistFilterManual.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get travelChecklistFilterManual;

  /// No description provided for @travelChecklistFilterActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get travelChecklistFilterActivities;

  /// No description provided for @travelChecklistFilterExcursions.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get travelChecklistFilterExcursions;

  /// No description provided for @travelChecklistSectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming preparations'**
  String get travelChecklistSectionUpcoming;

  /// No description provided for @travelChecklistSectionManual.
  ///
  /// In en, this message translates to:
  /// **'My plans'**
  String get travelChecklistSectionManual;

  /// No description provided for @travelChecklistSectionPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get travelChecklistSectionPast;

  /// No description provided for @travelChecklistSourceManual.
  ///
  /// In en, this message translates to:
  /// **'My checklist'**
  String get travelChecklistSourceManual;

  /// No description provided for @travelChecklistSourceActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get travelChecklistSourceActivity;

  /// No description provided for @travelChecklistSourceExcursion.
  ///
  /// In en, this message translates to:
  /// **'Excursion'**
  String get travelChecklistSourceExcursion;

  /// No description provided for @travelChecklistFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No checklists here'**
  String get travelChecklistFilterEmptyTitle;

  /// No description provided for @travelChecklistFilterEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another filter or create a new preparation.'**
  String get travelChecklistFilterEmptyMessage;

  /// No description provided for @travelChecklistContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip context'**
  String get travelChecklistContextTitle;

  /// No description provided for @travelChecklistContextDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get travelChecklistContextDestination;

  /// No description provided for @travelChecklistContextDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get travelChecklistContextDates;

  /// No description provided for @travelChecklistContextTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get travelChecklistContextTransport;

  /// No description provided for @travelChecklistContextActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get travelChecklistContextActivities;

  /// No description provided for @travelChecklistContextTravelerProfile.
  ///
  /// In en, this message translates to:
  /// **'Travelers'**
  String get travelChecklistContextTravelerProfile;

  /// No description provided for @travelChecklistContextNoActivities.
  ///
  /// In en, this message translates to:
  /// **'No special activities'**
  String get travelChecklistContextNoActivities;

  /// No description provided for @travelChecklistContextWithChildren.
  ///
  /// In en, this message translates to:
  /// **'With children'**
  String get travelChecklistContextWithChildren;

  /// No description provided for @travelChecklistReminderDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{days} days before the trip'**
  String travelChecklistReminderDaysBefore(Object days);

  /// No description provided for @travelChecklistReminderOnTripDay.
  ///
  /// In en, this message translates to:
  /// **'On trip day'**
  String get travelChecklistReminderOnTripDay;

  /// No description provided for @travelChecklistReminderDueDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String travelChecklistReminderDueDate(Object date);

  /// No description provided for @travelChecklistTransportFlight.
  ///
  /// In en, this message translates to:
  /// **'Airplane'**
  String get travelChecklistTransportFlight;

  /// No description provided for @travelChecklistTransportTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get travelChecklistTransportTrain;

  /// No description provided for @travelChecklistTransportBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get travelChecklistTransportBus;

  /// No description provided for @travelChecklistTransportCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get travelChecklistTransportCar;

  /// No description provided for @travelChecklistTransportMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get travelChecklistTransportMotorcycle;

  /// No description provided for @travelChecklistTransportFerry.
  ///
  /// In en, this message translates to:
  /// **'Ferry'**
  String get travelChecklistTransportFerry;

  /// No description provided for @travelChecklistTransportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get travelChecklistTransportOther;

  /// No description provided for @travelChecklistActivityWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get travelChecklistActivityWalking;

  /// No description provided for @travelChecklistActivityHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get travelChecklistActivityHiking;

  /// No description provided for @travelChecklistActivityCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get travelChecklistActivityCulture;

  /// No description provided for @travelChecklistActivityFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get travelChecklistActivityFood;

  /// No description provided for @travelChecklistActivityBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get travelChecklistActivityBeach;

  /// No description provided for @travelChecklistActivityMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museums'**
  String get travelChecklistActivityMuseum;

  /// No description provided for @travelChecklistActivityShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get travelChecklistActivityShopping;

  /// No description provided for @travelChecklistActivityNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get travelChecklistActivityNightlife;

  /// No description provided for @travelChecklistReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get travelChecklistReadiness;

  /// No description provided for @travelChecklistSystemReadiness.
  ///
  /// In en, this message translates to:
  /// **'System readiness'**
  String get travelChecklistSystemReadiness;

  /// No description provided for @travelChecklistPersonalProgress.
  ///
  /// In en, this message translates to:
  /// **'Personal items: {done} of {total}'**
  String travelChecklistPersonalProgress(int done, int total);

  /// No description provided for @travelChecklistSeasonalProfile.
  ///
  /// In en, this message translates to:
  /// **'Seasonal profile'**
  String get travelChecklistSeasonalProfile;

  /// No description provided for @travelChecklistChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get travelChecklistChecklist;

  /// No description provided for @travelChecklistItemsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search checklist items'**
  String get travelChecklistItemsSearchHint;

  /// No description provided for @travelChecklistItemsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items found for this search.'**
  String get travelChecklistItemsSearchEmpty;

  /// No description provided for @travelChecklistAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get travelChecklistAddItem;

  /// No description provided for @travelChecklistCustomItemBadge.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get travelChecklistCustomItemBadge;

  /// No description provided for @travelChecklistCustomItemTitle.
  ///
  /// In en, this message translates to:
  /// **'What to take or do'**
  String get travelChecklistCustomItemTitle;

  /// No description provided for @travelChecklistCustomItemTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: camera charger'**
  String get travelChecklistCustomItemTitleHint;

  /// No description provided for @travelChecklistCustomItemNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get travelChecklistCustomItemNote;

  /// No description provided for @travelChecklistCustomItemAdditional.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get travelChecklistCustomItemAdditional;

  /// No description provided for @travelChecklistCustomItemReuse.
  ///
  /// In en, this message translates to:
  /// **'Add to future checklists'**
  String get travelChecklistCustomItemReuse;

  /// No description provided for @travelChecklistCustomItemSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get travelChecklistCustomItemSave;

  /// No description provided for @travelChecklistCustomItemEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get travelChecklistCustomItemEdit;

  /// No description provided for @travelChecklistCustomItemDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get travelChecklistCustomItemDelete;

  /// No description provided for @travelChecklistCustomItemCreated.
  ///
  /// In en, this message translates to:
  /// **'Item added'**
  String get travelChecklistCustomItemCreated;

  /// No description provided for @travelChecklistCustomItemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated'**
  String get travelChecklistCustomItemUpdated;

  /// No description provided for @travelChecklistCustomItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get travelChecklistCustomItemDeleted;

  /// No description provided for @travelChecklistCustomItemFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the personal item. Try again later.'**
  String get travelChecklistCustomItemFailed;

  /// No description provided for @travelChecklistCustomItemTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the item title.'**
  String get travelChecklistCustomItemTitleRequired;

  /// No description provided for @travelChecklistCarrySearch.
  ///
  /// In en, this message translates to:
  /// **'Can I bring it?'**
  String get travelChecklistCarrySearch;

  /// No description provided for @travelChecklistCarrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Power bank, liquids, scissors'**
  String get travelChecklistCarrySearchHint;

  /// No description provided for @travelChecklistSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get travelChecklistSearch;

  /// No description provided for @travelChecklistNoCarryResults.
  ///
  /// In en, this message translates to:
  /// **'No matching rule yet. Check the airline or official authority.'**
  String get travelChecklistNoCarryResults;

  /// No description provided for @travelChecklistCarryOn.
  ///
  /// In en, this message translates to:
  /// **'Carry-on'**
  String get travelChecklistCarryOn;

  /// No description provided for @travelChecklistCheckedBaggage.
  ///
  /// In en, this message translates to:
  /// **'Checked baggage'**
  String get travelChecklistCheckedBaggage;

  /// No description provided for @travelChecklistRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get travelChecklistRetry;

  /// No description provided for @travelChecklistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the checklist. Check your connection and try again.'**
  String get travelChecklistLoadFailed;

  /// No description provided for @travelChecklistOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline copy'**
  String get travelChecklistOfflineTitle;

  /// No description provided for @travelChecklistOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Showing the last saved checklist. Some statuses may sync when the connection returns.'**
  String get travelChecklistOfflineMessage;

  /// No description provided for @travelChecklistReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get travelChecklistReminders;

  /// No description provided for @travelChecklistAssignToMe.
  ///
  /// In en, this message translates to:
  /// **'I will take it'**
  String get travelChecklistAssignToMe;

  /// No description provided for @travelChecklistAssignedToMe.
  ///
  /// In en, this message translates to:
  /// **'I am taking it'**
  String get travelChecklistAssignedToMe;

  /// No description provided for @travelChecklistAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get travelChecklistAssigned;

  /// No description provided for @travelChecklistAssignmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update assignment. Try again later.'**
  String get travelChecklistAssignmentFailed;

  /// No description provided for @travelChecklistFeedbackHelpful.
  ///
  /// In en, this message translates to:
  /// **'Useful'**
  String get travelChecklistFeedbackHelpful;

  /// No description provided for @travelChecklistFeedbackNotHelpful.
  ///
  /// In en, this message translates to:
  /// **'Not useful'**
  String get travelChecklistFeedbackNotHelpful;

  /// No description provided for @travelChecklistFeedbackAddNextTime.
  ///
  /// In en, this message translates to:
  /// **'Add next time'**
  String get travelChecklistFeedbackAddNextTime;

  /// No description provided for @travelChecklistFeedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we will use this'**
  String get travelChecklistFeedbackSent;

  /// No description provided for @travelChecklistFeedbackHelpfulSaved.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved: we will show items like this more often.'**
  String get travelChecklistFeedbackHelpfulSaved;

  /// No description provided for @travelChecklistFeedbackNotHelpfulSaved.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved: we will show items like this less often.'**
  String get travelChecklistFeedbackNotHelpfulSaved;

  /// No description provided for @travelChecklistFeedbackAddNextTimeSaved.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved: we will add this to future checklists.'**
  String get travelChecklistFeedbackAddNextTimeSaved;

  /// No description provided for @travelChecklistFeedbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send feedback. Try again later.'**
  String get travelChecklistFeedbackFailed;

  /// No description provided for @travelChecklistUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get travelChecklistUnknown;

  /// No description provided for @travelChecklistReadinessNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get travelChecklistReadinessNotReady;

  /// No description provided for @travelChecklistReadinessAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get travelChecklistReadinessAtRisk;

  /// No description provided for @travelChecklistReadinessOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get travelChecklistReadinessOnTrack;

  /// No description provided for @travelChecklistReadinessAlmostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready'**
  String get travelChecklistReadinessAlmostReady;

  /// No description provided for @travelChecklistReadinessReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get travelChecklistReadinessReady;

  /// No description provided for @travelChecklistReadinessReadyWithWarnings.
  ///
  /// In en, this message translates to:
  /// **'Ready with warnings'**
  String get travelChecklistReadinessReadyWithWarnings;

  /// No description provided for @travelChecklistPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get travelChecklistPriorityCritical;

  /// No description provided for @travelChecklistPriorityEssential.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get travelChecklistPriorityEssential;

  /// No description provided for @travelChecklistPriorityImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get travelChecklistPriorityImportant;

  /// No description provided for @travelChecklistPriorityRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get travelChecklistPriorityRecommended;

  /// No description provided for @travelChecklistPriorityOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get travelChecklistPriorityOptional;

  /// No description provided for @travelChecklistTemperatureCold.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get travelChecklistTemperatureCold;

  /// No description provided for @travelChecklistTemperatureMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get travelChecklistTemperatureMild;

  /// No description provided for @travelChecklistTemperatureWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get travelChecklistTemperatureWarm;

  /// No description provided for @travelChecklistTemperatureHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get travelChecklistTemperatureHot;

  /// No description provided for @travelChecklistTemperatureVeryHot.
  ///
  /// In en, this message translates to:
  /// **'Very hot'**
  String get travelChecklistTemperatureVeryHot;

  /// No description provided for @travelChecklistPrecipitationDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get travelChecklistPrecipitationDry;

  /// No description provided for @travelChecklistPrecipitationOccasionalRain.
  ///
  /// In en, this message translates to:
  /// **'Occasional rain'**
  String get travelChecklistPrecipitationOccasionalRain;

  /// No description provided for @travelChecklistPrecipitationRainy.
  ///
  /// In en, this message translates to:
  /// **'Rainy'**
  String get travelChecklistPrecipitationRainy;

  /// No description provided for @travelChecklistPrecipitationMonsoon.
  ///
  /// In en, this message translates to:
  /// **'Monsoon'**
  String get travelChecklistPrecipitationMonsoon;

  /// No description provided for @travelChecklistPrecipitationSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get travelChecklistPrecipitationSnow;

  /// No description provided for @travelChecklistSkySunny.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get travelChecklistSkySunny;

  /// No description provided for @travelChecklistSkyMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed clouds'**
  String get travelChecklistSkyMixed;

  /// No description provided for @travelChecklistSkyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get travelChecklistSkyCloudy;

  /// No description provided for @travelChecklistRiskCold.
  ///
  /// In en, this message translates to:
  /// **'Cold risk'**
  String get travelChecklistRiskCold;

  /// No description provided for @travelChecklistRiskDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get travelChecklistRiskDry;

  /// No description provided for @travelChecklistRiskHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get travelChecklistRiskHeat;

  /// No description provided for @travelChecklistRiskHighUv.
  ///
  /// In en, this message translates to:
  /// **'High UV'**
  String get travelChecklistRiskHighUv;

  /// No description provided for @travelChecklistRiskHumid.
  ///
  /// In en, this message translates to:
  /// **'Humid'**
  String get travelChecklistRiskHumid;

  /// No description provided for @travelChecklistRiskIcy.
  ///
  /// In en, this message translates to:
  /// **'Icy'**
  String get travelChecklistRiskIcy;

  /// No description provided for @travelChecklistRiskMixedWeather.
  ///
  /// In en, this message translates to:
  /// **'Changeable weather'**
  String get travelChecklistRiskMixedWeather;

  /// No description provided for @travelChecklistRiskRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get travelChecklistRiskRain;

  /// No description provided for @travelChecklistRiskWindy.
  ///
  /// In en, this message translates to:
  /// **'Windy'**
  String get travelChecklistRiskWindy;

  /// No description provided for @travelChecklistCarryItemPowerBank.
  ///
  /// In en, this message translates to:
  /// **'Power bank'**
  String get travelChecklistCarryItemPowerBank;

  /// No description provided for @travelChecklistCarryItemTravelVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa / documents'**
  String get travelChecklistCarryItemTravelVisa;

  /// No description provided for @travelChecklistCarryItemLiquids.
  ///
  /// In en, this message translates to:
  /// **'Liquids'**
  String get travelChecklistCarryItemLiquids;

  /// No description provided for @travelChecklistCarryItemSharpItems.
  ///
  /// In en, this message translates to:
  /// **'Sharp items'**
  String get travelChecklistCarryItemSharpItems;

  /// No description provided for @travelChecklistCarryAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get travelChecklistCarryAllowed;

  /// No description provided for @travelChecklistCarryAllowedWithConditions.
  ///
  /// In en, this message translates to:
  /// **'Allowed with conditions'**
  String get travelChecklistCarryAllowedWithConditions;

  /// No description provided for @travelChecklistCarryProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited'**
  String get travelChecklistCarryProhibited;

  /// No description provided for @travelChecklistCarryCheckAuthority.
  ///
  /// In en, this message translates to:
  /// **'Check rules'**
  String get travelChecklistCarryCheckAuthority;

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

  /// No description provided for @commonPaginationPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get commonPaginationPrevious;

  /// No description provided for @commonPaginationNext.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get commonPaginationNext;

  /// No description provided for @commonPaginationLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String commonPaginationLabel(Object current, Object total);

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

  /// No description provided for @drawerStatusVerifiedGuide.
  ///
  /// In en, this message translates to:
  /// **'Verified guide'**
  String get drawerStatusVerifiedGuide;

  /// No description provided for @drawerStatusGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get drawerStatusGuide;

  /// No description provided for @drawerStatusGuideRevoked.
  ///
  /// In en, this message translates to:
  /// **'Guide status revoked'**
  String get drawerStatusGuideRevoked;

  /// No description provided for @drawerStatusTraveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get drawerStatusTraveler;

  /// No description provided for @drawerStatusCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get drawerStatusCompleteProfile;

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

  /// No description provided for @profilePhoneVerificationSection.
  ///
  /// In en, this message translates to:
  /// **'Phone verification'**
  String get profilePhoneVerificationSection;

  /// No description provided for @profilePhoneVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact number'**
  String get profilePhoneVerificationTitle;

  /// No description provided for @profilePhoneVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Verify your number by SMS so we can protect bookings and sensitive actions.'**
  String get profilePhoneVerificationDescription;

  /// No description provided for @profilePhoneVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone verified'**
  String get profilePhoneVerifiedTitle;

  /// No description provided for @profilePhoneVerifiedDescription.
  ///
  /// In en, this message translates to:
  /// **'This number is used as a trusted contact for important actions.'**
  String get profilePhoneVerifiedDescription;

  /// No description provided for @profilePhoneVerifiedAs.
  ///
  /// In en, this message translates to:
  /// **'Verified: {phone}'**
  String profilePhoneVerifiedAs(Object phone);

  /// No description provided for @profilePhoneCurrentVerifiedAs.
  ///
  /// In en, this message translates to:
  /// **'Current number: {phone}'**
  String profilePhoneCurrentVerifiedAs(Object phone);

  /// No description provided for @profilePhoneSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get profilePhoneSendCode;

  /// No description provided for @profilePhoneCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String profilePhoneCodeSentTo(Object phone);

  /// No description provided for @profilePhoneCodeHint.
  ///
  /// In en, this message translates to:
  /// **'SMS code'**
  String get profilePhoneCodeHint;

  /// No description provided for @profilePhoneVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify phone'**
  String get profilePhoneVerifyCode;

  /// No description provided for @profilePhoneResendCode.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get profilePhoneResendCode;

  /// No description provided for @profilePhoneResendIn.
  ///
  /// In en, this message translates to:
  /// **'Again in {seconds}s'**
  String profilePhoneResendIn(Object seconds);

  /// No description provided for @profilePhoneChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get profilePhoneChangeNumber;

  /// No description provided for @profilePhoneCancelChange.
  ///
  /// In en, this message translates to:
  /// **'Keep current number'**
  String get profilePhoneCancelChange;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the number in international format, for example +77011234567.'**
  String get profilePhoneInvalid;

  /// No description provided for @profilePhoneAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'This number is already verified. Enter a different number.'**
  String get profilePhoneAlreadyVerified;

  /// No description provided for @profilePhoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This number is already used or unavailable.'**
  String get profilePhoneUnavailable;

  /// No description provided for @profilePhoneCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'The code expired. Send a new code.'**
  String get profilePhoneCodeExpired;

  /// No description provided for @profilePhoneCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get profilePhoneCodeInvalid;

  /// No description provided for @profilePhoneVerificationLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect attempts. Request a new code later.'**
  String get profilePhoneVerificationLocked;

  /// No description provided for @profilePhoneRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait before sending again.'**
  String get profilePhoneRateLimited;

  /// No description provided for @profilePhoneVerificationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone verification is temporarily unavailable.'**
  String get profilePhoneVerificationUnavailable;

  /// No description provided for @profilePhoneVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to verify phone. Please try again.'**
  String get profilePhoneVerificationFailed;

  /// No description provided for @profilePhoneCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the SMS code.'**
  String get profilePhoneCodeRequired;

  /// No description provided for @profilePhoneStartRequired.
  ///
  /// In en, this message translates to:
  /// **'Send a code to the phone number first.'**
  String get profilePhoneStartRequired;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

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

  /// No description provided for @profileTimezoneSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Time zone, city, or UTC'**
  String get profileTimezoneSearchHint;

  /// No description provided for @profileTimezoneNoResults.
  ///
  /// In en, this message translates to:
  /// **'No time zones found'**
  String get profileTimezoneNoResults;

  /// No description provided for @profileTimezoneRecommendedForCountry.
  ///
  /// In en, this message translates to:
  /// **'Recommended for {country}'**
  String profileTimezoneRecommendedForCountry(Object country);

  /// No description provided for @timeDisplayYourTime.
  ///
  /// In en, this message translates to:
  /// **'Your time: {time}'**
  String timeDisplayYourTime(Object time);

  /// No description provided for @profileCountry.
  ///
  /// In en, this message translates to:
  /// **'Citizenship'**
  String get profileCountry;

  /// No description provided for @profileCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get profileCurrency;

  /// No description provided for @profileCurrencySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Currency, code, or symbol'**
  String get profileCurrencySearchHint;

  /// No description provided for @profileCurrencyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No currencies found'**
  String get profileCurrencyNoResults;

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

  /// No description provided for @guideVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide application'**
  String get guideVerificationTitle;

  /// No description provided for @guideVerificationStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String guideVerificationStepCounter(Object current, Object total);

  /// No description provided for @guideVerificationStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get guideVerificationStepIdentity;

  /// No description provided for @guideVerificationStepDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get guideVerificationStepDocument;

  /// No description provided for @guideVerificationStepLicense.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get guideVerificationStepLicense;

  /// No description provided for @guideVerificationStepSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get guideVerificationStepSubmit;

  /// No description provided for @guideVerificationHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your guide status'**
  String get guideVerificationHeroTitle;

  /// No description provided for @guideVerificationHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete the form and upload your documents so we can review your profile and unlock professional guide features.'**
  String get guideVerificationHeroSubtitle;

  /// No description provided for @guideVerificationIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get guideVerificationIdentitySection;

  /// No description provided for @guideVerificationFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get guideVerificationFullNameLabel;

  /// No description provided for @guideVerificationFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Exactly as shown on your ID'**
  String get guideVerificationFullNameHint;

  /// No description provided for @guideVerificationBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get guideVerificationBirthDateLabel;

  /// No description provided for @guideVerificationBirthDateHint.
  ///
  /// In en, this message translates to:
  /// **'DD.MM.YYYY'**
  String get guideVerificationBirthDateHint;

  /// No description provided for @guideVerificationNationalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get guideVerificationNationalityLabel;

  /// No description provided for @guideVerificationSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get guideVerificationSelectCountry;

  /// No description provided for @guideVerificationIdentityNotice.
  ///
  /// In en, this message translates to:
  /// **'We use these details only to verify your identity and guide status'**
  String get guideVerificationIdentityNotice;

  /// No description provided for @guideVerificationContinueToDocuments.
  ///
  /// In en, this message translates to:
  /// **'Continue to documents'**
  String get guideVerificationContinueToDocuments;

  /// No description provided for @guideVerificationDocumentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get guideVerificationDocumentTypeLabel;

  /// No description provided for @guideVerificationPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get guideVerificationPassport;

  /// No description provided for @guideVerificationNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get guideVerificationNationalId;

  /// No description provided for @guideVerificationUploadPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload an identity document'**
  String get guideVerificationUploadPhotoTitle;

  /// No description provided for @guideVerificationUploadPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide a clear photo or scan of the front side of your document.'**
  String get guideVerificationUploadPhotoSubtitle;

  /// No description provided for @guideVerificationNoGlare.
  ///
  /// In en, this message translates to:
  /// **'No glare'**
  String get guideVerificationNoGlare;

  /// No description provided for @guideVerificationNoGlareHint.
  ///
  /// In en, this message translates to:
  /// **'Take the photo in even light so every detail remains readable'**
  String get guideVerificationNoGlareHint;

  /// No description provided for @guideVerificationFullFrame.
  ///
  /// In en, this message translates to:
  /// **'Full frame'**
  String get guideVerificationFullFrame;

  /// No description provided for @guideVerificationFullFrameHint.
  ///
  /// In en, this message translates to:
  /// **'All edges of the document should be visible in the image'**
  String get guideVerificationFullFrameHint;

  /// No description provided for @guideVerificationTapToCapturePassport.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a document file'**
  String get guideVerificationTapToCapturePassport;

  /// No description provided for @guideVerificationFileFormatsShort.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG, PDF up to 10 MB'**
  String get guideVerificationFileFormatsShort;

  /// No description provided for @guideVerificationChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get guideVerificationChooseFile;

  /// No description provided for @guideVerificationReplaceFile.
  ///
  /// In en, this message translates to:
  /// **'Replace file'**
  String get guideVerificationReplaceFile;

  /// No description provided for @guideVerificationDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'I confirm that this document is valid, not expired, and the photo provided is clearly legible for automated verification systems'**
  String get guideVerificationDocumentConfirm;

  /// No description provided for @guideVerificationVerifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue verification'**
  String get guideVerificationVerifyContinue;

  /// No description provided for @guideVerificationCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials and license'**
  String get guideVerificationCredentialsTitle;

  /// No description provided for @guideVerificationCredentialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us which document confirms your experience and right to work as a guide.'**
  String get guideVerificationCredentialsSubtitle;

  /// No description provided for @guideVerificationLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification document type'**
  String get guideVerificationLicenseLabel;

  /// No description provided for @guideVerificationSelectLicenseType.
  ///
  /// In en, this message translates to:
  /// **'Select document type'**
  String get guideVerificationSelectLicenseType;

  /// No description provided for @guideVerificationOfficialExcursionGuideLicense.
  ///
  /// In en, this message translates to:
  /// **'Official excursion guide license'**
  String get guideVerificationOfficialExcursionGuideLicense;

  /// No description provided for @guideVerificationCityGuidePermit.
  ///
  /// In en, this message translates to:
  /// **'City guide permit'**
  String get guideVerificationCityGuidePermit;

  /// No description provided for @guideVerificationMuseumAccreditation.
  ///
  /// In en, this message translates to:
  /// **'Museum or venue accreditation'**
  String get guideVerificationMuseumAccreditation;

  /// No description provided for @guideVerificationUploadLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload the supporting document'**
  String get guideVerificationUploadLicenseTitle;

  /// No description provided for @guideVerificationUploadLicenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A certificate, license, or other professional document works here'**
  String get guideVerificationUploadLicenseSubtitle;

  /// No description provided for @guideVerificationAdditionalCertifications.
  ///
  /// In en, this message translates to:
  /// **'Additional skills'**
  String get guideVerificationAdditionalCertifications;

  /// No description provided for @guideVerificationUploadFirstAidTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a first aid certificate'**
  String get guideVerificationUploadFirstAidTitle;

  /// No description provided for @guideVerificationUploadFirstAidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: add a valid certificate to strengthen your application.'**
  String get guideVerificationUploadFirstAidSubtitle;

  /// No description provided for @guideVerificationUploadLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a language certificate'**
  String get guideVerificationUploadLanguageTitle;

  /// No description provided for @guideVerificationUploadLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: add a certificate that confirms your language proficiency.'**
  String get guideVerificationUploadLanguageSubtitle;

  /// No description provided for @guideVerificationFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get guideVerificationFirstAid;

  /// No description provided for @guideVerificationFirstAidHint.
  ///
  /// In en, this message translates to:
  /// **'You have current first aid training or a valid certificate'**
  String get guideVerificationFirstAidHint;

  /// No description provided for @guideVerificationLanguageProficiency.
  ///
  /// In en, this message translates to:
  /// **'Foreign languages'**
  String get guideVerificationLanguageProficiency;

  /// No description provided for @guideVerificationLanguageProficiencyHint.
  ///
  /// In en, this message translates to:
  /// **'You can host activities and excursions in more than one language'**
  String get guideVerificationLanguageProficiencyHint;

  /// No description provided for @guideVerificationTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Review timeline'**
  String get guideVerificationTimelineTitle;

  /// No description provided for @guideVerificationTimelineText.
  ///
  /// In en, this message translates to:
  /// **'We usually review applications within 1 to 3 business days. If we need more information, you will see it in your profile.'**
  String get guideVerificationTimelineText;

  /// No description provided for @guideVerificationReviewHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your details before sending'**
  String get guideVerificationReviewHeroTitle;

  /// No description provided for @guideVerificationReviewHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make sure everything is correct. Once submitted, the application goes to review.'**
  String get guideVerificationReviewHeroSubtitle;

  /// No description provided for @guideVerificationReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Application summary'**
  String get guideVerificationReviewTitle;

  /// No description provided for @guideVerificationEditInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get guideVerificationEditInfo;

  /// No description provided for @guideVerificationIdentityDocumentCard.
  ///
  /// In en, this message translates to:
  /// **'Identity document'**
  String get guideVerificationIdentityDocumentCard;

  /// No description provided for @guideVerificationProfessionalLicenseCard.
  ///
  /// In en, this message translates to:
  /// **'Professional document'**
  String get guideVerificationProfessionalLicenseCard;

  /// No description provided for @guideVerificationFirstAidCertificateCard.
  ///
  /// In en, this message translates to:
  /// **'First aid certificate'**
  String get guideVerificationFirstAidCertificateCard;

  /// No description provided for @guideVerificationLanguageCertificateCard.
  ///
  /// In en, this message translates to:
  /// **'Language certificate'**
  String get guideVerificationLanguageCertificateCard;

  /// No description provided for @guideVerificationVerifiedUpload.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get guideVerificationVerifiedUpload;

  /// No description provided for @guideVerificationTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get guideVerificationTermsTitle;

  /// No description provided for @guideVerificationTermsHeading.
  ///
  /// In en, this message translates to:
  /// **'I confirm that the information is accurate'**
  String get guideVerificationTermsHeading;

  /// No description provided for @guideVerificationTermsBody.
  ///
  /// In en, this message translates to:
  /// **'I understand that Inflap may reject the application if any information is inaccurate or the uploaded documents are not suitable.'**
  String get guideVerificationTermsBody;

  /// No description provided for @guideVerificationAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to document review and data processing for guide status verification'**
  String get guideVerificationAgreement;

  /// No description provided for @guideVerificationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get guideVerificationSubmit;

  /// No description provided for @guideVerificationReviewNote.
  ///
  /// In en, this message translates to:
  /// **'After submission, you can track the application status in your profile'**
  String get guideVerificationReviewNote;

  /// No description provided for @guideVerificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your application is already under review'**
  String get guideVerificationPendingTitle;

  /// No description provided for @guideVerificationPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We received your documents and are reviewing them now. You will see an update in your profile as soon as the status changes.'**
  String get guideVerificationPendingSubtitle;

  /// No description provided for @guideVerificationActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide status is already verified'**
  String get guideVerificationActiveTitle;

  /// No description provided for @guideVerificationActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is already active as a guide profile. No need to submit anything else.'**
  String get guideVerificationActiveSubtitle;

  /// No description provided for @guideVerificationRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your application needs updates'**
  String get guideVerificationRejectedTitle;

  /// No description provided for @guideVerificationRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The previous application was rejected. You can update the information and submit your documents again.'**
  String get guideVerificationRejectedSubtitle;

  /// No description provided for @guideVerificationDraftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You already have a saved draft application. Continue with the current data and send it for review when ready.'**
  String get guideVerificationDraftSubtitle;

  /// No description provided for @guideVerificationViewApplicationButton.
  ///
  /// In en, this message translates to:
  /// **'View application'**
  String get guideVerificationViewApplicationButton;

  /// No description provided for @guideVerificationContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get guideVerificationContinueButton;

  /// No description provided for @guideVerificationBackToProfile.
  ///
  /// In en, this message translates to:
  /// **'Back to profile'**
  String get guideVerificationBackToProfile;

  /// No description provided for @guideVerificationFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get guideVerificationFullNameRequired;

  /// No description provided for @guideVerificationFullNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter both first and last name'**
  String get guideVerificationFullNameInvalid;

  /// No description provided for @guideVerificationBirthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your date of birth'**
  String get guideVerificationBirthDateRequired;

  /// No description provided for @guideVerificationBirthDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date in DD.MM.YYYY format'**
  String get guideVerificationBirthDateInvalid;

  /// No description provided for @guideVerificationNationalityRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your nationality'**
  String get guideVerificationNationalityRequired;

  /// No description provided for @guideVerificationIdentityFileRequired.
  ///
  /// In en, this message translates to:
  /// **'Upload your identity document'**
  String get guideVerificationIdentityFileRequired;

  /// No description provided for @guideVerificationProfessionalFileRequired.
  ///
  /// In en, this message translates to:
  /// **'Upload your professional document'**
  String get guideVerificationProfessionalFileRequired;

  /// No description provided for @guideVerificationConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm that the document is valid and the photo is clearly legible'**
  String get guideVerificationConfirmationRequired;

  /// No description provided for @guideVerificationAgreementRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to agree to the document review'**
  String get guideVerificationAgreementRequired;

  /// No description provided for @guideVerificationUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file'**
  String get guideVerificationUploadFailed;

  /// No description provided for @guideVerificationUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Only JPG, PNG, WEBP, and PDF are supported'**
  String get guideVerificationUnsupportedFormat;

  /// No description provided for @guideVerificationSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit application'**
  String get guideVerificationSubmitFailed;

  /// No description provided for @guideVerificationDocumentsRequired.
  ///
  /// In en, this message translates to:
  /// **'Both an identity document and a professional document are required'**
  String get guideVerificationDocumentsRequired;

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

  /// No description provided for @profileIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile is incomplete'**
  String get profileIncompleteTitle;

  /// No description provided for @profileIncompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill in your nickname, first name, last name, and citizenship to unlock all Inflap features'**
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

  /// No description provided for @profileNicknameTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already taken'**
  String get profileNicknameTaken;

  /// No description provided for @profileNicknameOneTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Nickname can be set only once. After saving, it cannot be changed.'**
  String get profileNicknameOneTimeHint;

  /// No description provided for @profileNicknameChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking nickname...'**
  String get profileNicknameChecking;

  /// No description provided for @profileNicknameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Nickname is available'**
  String get profileNicknameAvailable;

  /// No description provided for @profileNicknameCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check nickname. Try again.'**
  String get profileNicknameCheckFailed;

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

  /// No description provided for @nicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nicknameLabel;

  /// No description provided for @nicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get nicknameRequired;

  /// No description provided for @profileNicknameLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'Nickname can be set only once. After saving, it cannot be changed.'**
  String get profileNicknameLockedDescription;

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

  /// No description provided for @profileCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your citizenship'**
  String get profileCountryRequired;

  /// No description provided for @profileRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileRequiredTitle;

  /// No description provided for @profileRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'To continue, enter your nickname, first name, last name, and citizenship in your profile. This helps reduce fake accounts and increases trust between users.'**
  String get profileRequiredDescription;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfileTitle;

  /// No description provided for @profileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied'**
  String get profileLinkCopied;

  /// No description provided for @profileVerifiedExplorer.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED GUIDE'**
  String get profileVerifiedExplorer;

  /// No description provided for @profileGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Inflap Guide'**
  String get profileGuideTitle;

  /// No description provided for @profileGuideRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Guide rating'**
  String get profileGuideRatingLabel;

  /// No description provided for @profileEmptyBioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'A few words about yourself help others get to know you better'**
  String get profileEmptyBioPlaceholder;

  /// No description provided for @profileBecomeGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a guide'**
  String get profileBecomeGuideTitle;

  /// No description provided for @profileBecomeGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Soon you will be able to apply and unlock a professional guide profile here.'**
  String get profileBecomeGuideSubtitle;

  /// No description provided for @guideVerificationRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide status revoked'**
  String get guideVerificationRevokedTitle;

  /// No description provided for @guideVerificationRevokedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your guide status was revoked by moderation. Guide tools and public offers are unavailable.'**
  String get guideVerificationRevokedSubtitle;

  /// No description provided for @guideVerificationRevokedSubtitleWithReason.
  ///
  /// In en, this message translates to:
  /// **'Your guide status was revoked by moderation. Reason: {reason}'**
  String guideVerificationRevokedSubtitleWithReason(Object reason);

  /// No description provided for @guideVerificationRevokedButton.
  ///
  /// In en, this message translates to:
  /// **'Status revoked'**
  String get guideVerificationRevokedButton;

  /// No description provided for @profileActivitiesStat.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get profileActivitiesStat;

  /// No description provided for @profileHostedCompletedStat.
  ///
  /// In en, this message translates to:
  /// **'Completed as host'**
  String get profileHostedCompletedStat;

  /// No description provided for @profileJoinedCompletedStat.
  ///
  /// In en, this message translates to:
  /// **'Completed as participant'**
  String get profileJoinedCompletedStat;

  /// No description provided for @profileReviewsStat.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get profileReviewsStat;

  /// No description provided for @profileStoriesStat.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get profileStoriesStat;

  /// No description provided for @profileFollowersStat.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowersStat;

  /// No description provided for @profileFollowersTitle.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowersTitle;

  /// No description provided for @profileFollowersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowersSearchHint;

  /// No description provided for @profileFollowersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get profileFollowersEmptyTitle;

  /// No description provided for @profileFollowersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When users follow this profile, they will appear here.'**
  String get profileFollowersEmptySubtitle;

  /// No description provided for @profileFollowersSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get profileFollowersSearchEmptyTitle;

  /// No description provided for @profileFollowersSearchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different query or clear the search.'**
  String get profileFollowersSearchEmptySubtitle;

  /// No description provided for @profileFollowersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load followers'**
  String get profileFollowersLoadFailed;

  /// No description provided for @profileConnectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends and following'**
  String get profileConnectionsTitle;

  /// No description provided for @profileConnectionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your friends and the people you follow.'**
  String get profileConnectionsSubtitle;

  /// No description provided for @profileConnectionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get profileConnectionsSearchHint;

  /// No description provided for @profileConnectionsFriendsTab.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get profileConnectionsFriendsTab;

  /// No description provided for @profileConnectionsFollowingTab.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileConnectionsFollowingTab;

  /// No description provided for @profileConnectionsFriendsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get profileConnectionsFriendsEmptyTitle;

  /// No description provided for @profileConnectionsFriendsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a friend request is accepted, that user will appear here.'**
  String get profileConnectionsFriendsEmptySubtitle;

  /// No description provided for @profileConnectionsFollowingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No following yet'**
  String get profileConnectionsFollowingEmptyTitle;

  /// No description provided for @profileConnectionsFollowingEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'People you follow will appear here.'**
  String get profileConnectionsFollowingEmptySubtitle;

  /// No description provided for @profileConnectionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the list'**
  String get profileConnectionsLoadFailed;

  /// No description provided for @profileConnectionsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get profileConnectionsSortRecent;

  /// No description provided for @profileConnectionsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileConnectionsSortName;

  /// No description provided for @profileConnectionsFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get profileConnectionsFiltersTitle;

  /// No description provided for @profileConnectionsFiltersShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get profileConnectionsFiltersShowResults;

  /// No description provided for @profileConnectionsFilterOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get profileConnectionsFilterOnlineOnly;

  /// No description provided for @profileConnectionsFilterOnlineOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show users who are currently online.'**
  String get profileConnectionsFilterOnlineOnlySubtitle;

  /// No description provided for @profileConnectionsFriendRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get profileConnectionsFriendRequestsTitle;

  /// No description provided for @profileConnectionsFriendRequestsViewAll.
  ///
  /// In en, this message translates to:
  /// **'All requests'**
  String get profileConnectionsFriendRequestsViewAll;

  /// No description provided for @profileConnectionsFriendRequestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No friend requests'**
  String get profileConnectionsFriendRequestsEmptyTitle;

  /// No description provided for @profileConnectionsFriendRequestsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'New incoming friend requests will appear here.'**
  String get profileConnectionsFriendRequestsEmptySubtitle;

  /// No description provided for @profileMyContentTitle.
  ///
  /// In en, this message translates to:
  /// **'My space'**
  String get profileMyContentTitle;

  /// No description provided for @profileJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'My journey'**
  String get profileJourneyTitle;

  /// No description provided for @profileUserRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'My routes'**
  String get profileUserRoutesTitle;

  /// No description provided for @profileUserRoutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved walks, city plans and routes shared by travelers'**
  String get profileUserRoutesSubtitle;

  /// No description provided for @profileSavedItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved items'**
  String get profileSavedItemsTitle;

  /// No description provided for @profileSavedItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved activities, places, and collections will appear here later.'**
  String get profileSavedItemsSubtitle;

  /// No description provided for @profileBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get profileBookingsTitle;

  /// No description provided for @profileBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orders and confirmed bookings will appear here soon.'**
  String get profileBookingsSubtitle;

  /// No description provided for @profileMyActivitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your activities and track your participation.'**
  String get profileMyActivitiesSubtitle;

  /// No description provided for @profilePreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferencesTitle;

  /// No description provided for @profileNotificationsRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsRowTitle;

  /// No description provided for @profileNotificationsRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push, email, and SMS updates for your activity flow'**
  String get profileNotificationsRowSubtitle;

  /// No description provided for @profileSecurityRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & data'**
  String get profileSecurityRowTitle;

  /// No description provided for @profileSecurityRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account protection, data export, and privacy controls'**
  String get profileSecurityRowSubtitle;

  /// No description provided for @profileHostedActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hosted activities'**
  String get profileHostedActivitiesTitle;

  /// No description provided for @profileHostedActivitiesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Public hosted activities will appear here once the backend exposes the author\'s public showcase.'**
  String get profileHostedActivitiesUnavailable;

  /// No description provided for @profileRecentActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activities'**
  String get profileRecentActivitiesTitle;

  /// No description provided for @profileViewAllActivities.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get profileViewAllActivities;

  /// No description provided for @profileActivitiesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load activities'**
  String get profileActivitiesLoadFailed;

  /// No description provided for @profileActivitiesLoadFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get profileActivitiesLoadFailedHint;

  /// No description provided for @profileActivitiesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get profileActivitiesEmptyTitle;

  /// No description provided for @profileActivitiesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed public activities for this user will appear here.'**
  String get profileActivitiesEmptySubtitle;

  /// No description provided for @profileUserActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'User activities'**
  String get profileUserActivitiesTitle;

  /// No description provided for @profileUserActivitiesHostedTab.
  ///
  /// In en, this message translates to:
  /// **'Hosted'**
  String get profileUserActivitiesHostedTab;

  /// No description provided for @profileUserActivitiesVisitedTab.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get profileUserActivitiesVisitedTab;

  /// No description provided for @profileUserActivitiesHostedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No hosted activities yet'**
  String get profileUserActivitiesHostedEmptyTitle;

  /// No description provided for @profileUserActivitiesHostedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When this user completes a public activity as the host, it will appear here.'**
  String get profileUserActivitiesHostedEmptySubtitle;

  /// No description provided for @profileUserActivitiesVisitedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No visited activities yet'**
  String get profileUserActivitiesVisitedEmptyTitle;

  /// No description provided for @profileUserActivitiesVisitedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When this user attends a completed public activity, it will appear here.'**
  String get profileUserActivitiesVisitedEmptySubtitle;

  /// No description provided for @profilePopularStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular posts'**
  String get profilePopularStoriesTitle;

  /// No description provided for @profileViewAllStories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get profileViewAllStories;

  /// No description provided for @profileStoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts'**
  String get profileStoriesLoadFailed;

  /// No description provided for @profileStoriesLoadFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get profileStoriesLoadFailedHint;

  /// No description provided for @profileStoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get profileStoriesEmptyTitle;

  /// No description provided for @profileStoriesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Published posts from this user will appear here.'**
  String get profileStoriesEmptySubtitle;

  /// No description provided for @profileUserStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'User posts'**
  String get profileUserStoriesTitle;

  /// No description provided for @profileStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent posts'**
  String get profileStoriesTitle;

  /// No description provided for @profileStoriesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Public posts and travel articles are not available in the app yet.'**
  String get profileStoriesUnavailable;

  /// No description provided for @profileUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get profileUnavailableTitle;

  /// No description provided for @profileFollowAction.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get profileFollowAction;

  /// No description provided for @profileFollowingAction.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowingAction;

  /// No description provided for @profileUnfollowTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfollow user?'**
  String get profileUnfollowTitle;

  /// No description provided for @profileUnfollowDescription.
  ///
  /// In en, this message translates to:
  /// **'You will stop seeing this user\'s updates in your feed.'**
  String get profileUnfollowDescription;

  /// No description provided for @profileUnfollowConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get profileUnfollowConfirm;

  /// No description provided for @profileUnfollowAction.
  ///
  /// In en, this message translates to:
  /// **'Stop following'**
  String get profileUnfollowAction;

  /// No description provided for @profileFollowUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update follow status'**
  String get profileFollowUpdateFailed;

  /// No description provided for @profileAddFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get profileAddFriendAction;

  /// No description provided for @profileFriendRequestSentAction.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get profileFriendRequestSentAction;

  /// No description provided for @profileFriendRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend request'**
  String get profileFriendRequestTitle;

  /// No description provided for @profileFriendRequestAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileFriendRequestAcceptAction;

  /// No description provided for @profileFriendRequestDeclineAction.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get profileFriendRequestDeclineAction;

  /// No description provided for @profileAcceptFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get profileAcceptFriendAction;

  /// No description provided for @profileDeclineFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get profileDeclineFriendAction;

  /// No description provided for @profileFriendsAction.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get profileFriendsAction;

  /// No description provided for @profileRemoveFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get profileRemoveFriendAction;

  /// No description provided for @profileRemoveFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get profileRemoveFriendTitle;

  /// No description provided for @profileRemoveFriendDescription.
  ///
  /// In en, this message translates to:
  /// **'You will no longer be able to invite this user as a friend until a new request is accepted.'**
  String get profileRemoveFriendDescription;

  /// No description provided for @profileRemoveFriendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profileRemoveFriendConfirm;

  /// No description provided for @profileFriendshipUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update friendship status'**
  String get profileFriendshipUpdateFailed;

  /// No description provided for @profileMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get profileMessageAction;

  /// No description provided for @profileMessageOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat. Please try again.'**
  String get profileMessageOpenFailed;

  /// No description provided for @profileSettingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettingsPageTitle;

  /// No description provided for @profileSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChangesButton;

  /// No description provided for @profileDeactivateAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get profileDeactivateAccountLabel;

  /// No description provided for @profileSettingsAvatarDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Profile photo editing will be available in a future update.'**
  String get profileSettingsAvatarDisabledHint;

  /// No description provided for @profileSettingsAvatarUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the avatar or edit icon to choose a profile photo.'**
  String get profileSettingsAvatarUploadHint;

  /// No description provided for @profileSettingsAvatarUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading your new profile photo...'**
  String get profileSettingsAvatarUploading;

  /// No description provided for @profileSettingsAvatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile photo'**
  String get profileSettingsAvatarUploadFailed;

  /// No description provided for @profileSettingsAvatarUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Profile photo must be JPG, PNG, or WEBP'**
  String get profileSettingsAvatarUnsupportedFormat;

  /// No description provided for @profileSettingsDescriptionSection.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get profileSettingsDescriptionSection;

  /// No description provided for @profileSettingsDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileSettingsDetailsSection;

  /// No description provided for @profileSettingsServiceCitiesSection.
  ///
  /// In en, this message translates to:
  /// **'Service cities'**
  String get profileSettingsServiceCitiesSection;

  /// No description provided for @profileSettingsServiceCitiesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Public service cities are not supported by the backend yet, so this block stays inactive for now.'**
  String get profileSettingsServiceCitiesUnavailable;

  /// No description provided for @profileSettingsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get profileSettingsAddNew;

  /// No description provided for @profileAccountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountSectionTitle;

  /// No description provided for @profileSettingsEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name, photo, bio, and core profile details'**
  String get profileSettingsEditSubtitle;

  /// No description provided for @profileOverviewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile overview'**
  String get profileOverviewSectionTitle;

  /// No description provided for @profileMoreSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get profileMoreSectionTitle;

  /// No description provided for @profileGuideWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide workspace'**
  String get profileGuideWorkspaceTitle;

  /// No description provided for @profileGuideWorkspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professional guide tools are not available in the mobile app yet.'**
  String get profileGuideWorkspaceSubtitle;

  /// No description provided for @profileGuideDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide dashboard'**
  String get profileGuideDashboardTitle;

  /// No description provided for @profileGuideDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage offers, client bookings, and completed excursions.'**
  String get profileGuideDashboardSubtitle;

  /// No description provided for @profileSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get profileSupportTitle;

  /// No description provided for @profileSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help center and support requests will be added later.'**
  String get profileSupportSubtitle;

  /// No description provided for @profileNotificationsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsPageTitle;

  /// No description provided for @profileNotificationsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay in sync'**
  String get profileNotificationsHeroTitle;

  /// No description provided for @profileNotificationsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune push, quiet hours, and fallback channels so Inflap sends what matters without getting noisy.'**
  String get profileNotificationsHeroSubtitle;

  /// No description provided for @profileNotificationsDeliverySection.
  ///
  /// In en, this message translates to:
  /// **'Push delivery'**
  String get profileNotificationsDeliverySection;

  /// No description provided for @profileNotificationsCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Push categories'**
  String get profileNotificationsCategoriesSection;

  /// No description provided for @profileNotificationsQuietHoursSection.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get profileNotificationsQuietHoursSection;

  /// No description provided for @profileNotificationsChannelsSection.
  ///
  /// In en, this message translates to:
  /// **'Fallback channels'**
  String get profileNotificationsChannelsSection;

  /// No description provided for @profileNotificationsActivitySection.
  ///
  /// In en, this message translates to:
  /// **'Activities & participation'**
  String get profileNotificationsActivitySection;

  /// No description provided for @profileNotificationsDiscoverySection.
  ///
  /// In en, this message translates to:
  /// **'Discovery & offers'**
  String get profileNotificationsDiscoverySection;

  /// No description provided for @profileNotificationsPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get profileNotificationsPushTitle;

  /// No description provided for @profileNotificationsPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Master push switch for this device. The in-app inbox will keep saving notifications.'**
  String get profileNotificationsPushSubtitle;

  /// No description provided for @profileNotificationsPushPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Push is paused'**
  String get profileNotificationsPushPausedTitle;

  /// No description provided for @profileNotificationsPushPausedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will stop sending device push, while important events remain available in the in-app notification center.'**
  String get profileNotificationsPushPausedSubtitle;

  /// No description provided for @profileNotificationsPushEnabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Push enabled'**
  String get profileNotificationsPushEnabledStatus;

  /// No description provided for @profileNotificationsPushPausedStatus.
  ///
  /// In en, this message translates to:
  /// **'Push paused'**
  String get profileNotificationsPushPausedStatus;

  /// No description provided for @profileNotificationsEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get profileNotificationsEmailTitle;

  /// No description provided for @profileNotificationsEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmations, reminders, and useful updates sent to your inbox.'**
  String get profileNotificationsEmailSubtitle;

  /// No description provided for @profileNotificationsSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS notifications'**
  String get profileNotificationsSmsTitle;

  /// No description provided for @profileNotificationsSmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short critical updates and confirmations by text message.'**
  String get profileNotificationsSmsSubtitle;

  /// No description provided for @profileNotificationsActivityPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get profileNotificationsActivityPushTitle;

  /// No description provided for @profileNotificationsActivityPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New participants, status changes, reschedules, and reminders for your activities.'**
  String get profileNotificationsActivityPushSubtitle;

  /// No description provided for @profileNotificationsExcursionPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get profileNotificationsExcursionPushTitle;

  /// No description provided for @profileNotificationsExcursionPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings, schedule updates, requests, publishing statuses, and excursion events.'**
  String get profileNotificationsExcursionPushSubtitle;

  /// No description provided for @profileNotificationsChatPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get profileNotificationsChatPushTitle;

  /// No description provided for @profileNotificationsChatPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New messages, invitations, and important replies in chats.'**
  String get profileNotificationsChatPushSubtitle;

  /// No description provided for @profileNotificationsMarketingTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections & offers'**
  String get profileNotificationsMarketingTitle;

  /// No description provided for @profileNotificationsMarketingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Travel inspiration, place collections, and personal offers. You can turn this off without losing service notifications.'**
  String get profileNotificationsMarketingSubtitle;

  /// No description provided for @profileNotificationsSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'System and security notifications'**
  String get profileNotificationsSystemTitle;

  /// No description provided for @profileNotificationsSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important account security, payment, and access messages cannot be disabled in the app.'**
  String get profileNotificationsSystemSubtitle;

  /// No description provided for @profileNotificationsQuietHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Do not disturb'**
  String get profileNotificationsQuietHoursTitle;

  /// No description provided for @profileNotificationsQuietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Regular push will stay quiet from {start} to {end}. Urgent high-priority notifications are delivered immediately.'**
  String profileNotificationsQuietHoursSubtitle(Object start, Object end);

  /// No description provided for @profileNotificationsQuietHoursStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get profileNotificationsQuietHoursStart;

  /// No description provided for @profileNotificationsQuietHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get profileNotificationsQuietHoursEnd;

  /// No description provided for @profileNotificationsQuietHoursTimezone.
  ///
  /// In en, this message translates to:
  /// **'Using current timezone: {timezone}'**
  String profileNotificationsQuietHoursTimezone(Object timezone);

  /// No description provided for @profileNotificationsQuietHoursEnabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours on'**
  String get profileNotificationsQuietHoursEnabledStatus;

  /// No description provided for @profileNotificationsQuietHoursDisabledStatus.
  ///
  /// In en, this message translates to:
  /// **'No quiet hours'**
  String get profileNotificationsQuietHoursDisabledStatus;

  /// No description provided for @profileNotificationsPreferencesLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load push settings'**
  String get profileNotificationsPreferencesLoadFailedTitle;

  /// No description provided for @profileNotificationsPreferencesLoadFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection. Email and SMS can still be changed separately, but push settings are temporarily unavailable.'**
  String get profileNotificationsPreferencesLoadFailedSubtitle;

  /// No description provided for @profileNotificationsDarkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get profileNotificationsDarkModeTitle;

  /// No description provided for @profileNotificationsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This setting will arrive later. For now the app uses the current product palette.'**
  String get profileNotificationsDarkModeSubtitle;

  /// No description provided for @profileNotificationsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update notification settings'**
  String get profileNotificationsSaveFailed;

  /// No description provided for @profileSecurityPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & data'**
  String get profileSecurityPageTitle;

  /// No description provided for @profileSecurityHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect access'**
  String get profileSecurityHeroTitle;

  /// No description provided for @profileSecurityHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This section will collect account protection tools, data export, and privacy controls.'**
  String get profileSecurityHeroSubtitle;

  /// No description provided for @profileSecurityAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account protection'**
  String get profileSecurityAccountSection;

  /// No description provided for @profileSecurityDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get profileSecurityDataSection;

  /// No description provided for @profileSecurityPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileSecurityPasswordTitle;

  /// No description provided for @profileSecurityPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your current password and a one-time email code.'**
  String get profileSecurityPasswordSubtitle;

  /// No description provided for @profileSecurityPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get profileSecurityPasswordAction;

  /// No description provided for @profileSecurityPasswordSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileSecurityPasswordSheetTitle;

  /// No description provided for @profileSecurityPasswordSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First confirm your current password. Then we will send a code to the linked email.'**
  String get profileSecurityPasswordSheetSubtitle;

  /// No description provided for @profileSecurityPasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileSecurityPasswordCurrentLabel;

  /// No description provided for @profileSecurityPasswordCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get profileSecurityPasswordCurrentHint;

  /// No description provided for @profileSecurityPasswordCodeNotice.
  ///
  /// In en, this message translates to:
  /// **'The code was sent to the verified account email.'**
  String get profileSecurityPasswordCodeNotice;

  /// No description provided for @profileSecurityPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profileSecurityPasswordNewLabel;

  /// No description provided for @profileSecurityPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get profileSecurityPasswordConfirmLabel;

  /// No description provided for @profileSecurityPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get profileSecurityPasswordSendCode;

  /// No description provided for @profileSecurityPasswordSave.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get profileSecurityPasswordSave;

  /// No description provided for @profileSecurityPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get profileSecurityPasswordSuccess;

  /// No description provided for @profileSecurityPasswordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the password. Check the details and try again.'**
  String get profileSecurityPasswordChangeFailed;

  /// No description provided for @profileSecurityPasswordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get profileSecurityPasswordMismatchError;

  /// No description provided for @profileSecurityPasswordUnchangedError.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one'**
  String get profileSecurityPasswordUnchangedError;

  /// No description provided for @profileSecurityPasswordResendCodeCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String profileSecurityPasswordResendCodeCountdown(String time);

  /// No description provided for @profileSecurityTwoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional verification'**
  String get profileSecurityTwoFactorTitle;

  /// No description provided for @profileSecurityTwoFactorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Extra sign-in checks and sensitive action confirmation will be added later.'**
  String get profileSecurityTwoFactorSubtitle;

  /// No description provided for @profileSecurityDataExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data export'**
  String get profileSecurityDataExportTitle;

  /// No description provided for @profileSecurityDataExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exporting your data is not implemented on the backend yet.'**
  String get profileSecurityDataExportSubtitle;

  /// No description provided for @profileSecurityDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileSecurityDeleteTitle;

  /// No description provided for @profileSecurityDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Managed account deletion will be added after the backend flow is ready.'**
  String get profileSecurityDeleteSubtitle;

  /// No description provided for @profileStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get profileStatusEnabled;

  /// No description provided for @profileStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get profileStatusDisabled;

  /// No description provided for @profileDisabledSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get profileDisabledSoon;

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

  /// No description provided for @locationDetectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your location quickly. Try again or open the map.'**
  String get locationDetectionTimedOut;

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

  /// No description provided for @activityStatusCompletedEarly.
  ///
  /// In en, this message translates to:
  /// **'Completed early'**
  String get activityStatusCompletedEarly;

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

  /// No description provided for @activityExtend30MinutesButton.
  ///
  /// In en, this message translates to:
  /// **'Extend by 30 min'**
  String get activityExtend30MinutesButton;

  /// No description provided for @activityExtend60MinutesButton.
  ///
  /// In en, this message translates to:
  /// **'Extend by 1 hour'**
  String get activityExtend60MinutesButton;

  /// No description provided for @activityExtendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity end time updated'**
  String get activityExtendSuccess;

  /// No description provided for @activityExtendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to extend the activity'**
  String get activityExtendFailed;

  /// No description provided for @activityExtendNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This activity can no longer be extended'**
  String get activityExtendNotAllowed;

  /// No description provided for @activityCompleteNowButton.
  ///
  /// In en, this message translates to:
  /// **'Complete now'**
  String get activityCompleteNowButton;

  /// No description provided for @activityCompleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity completed'**
  String get activityCompleteSuccess;

  /// No description provided for @activityCompleteEarlySuccess.
  ///
  /// In en, this message translates to:
  /// **'Activity completed earlier than planned'**
  String get activityCompleteEarlySuccess;

  /// No description provided for @activityCompleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete the activity'**
  String get activityCompleteFailed;

  /// No description provided for @activityCompleteTooEarly.
  ///
  /// In en, this message translates to:
  /// **'You can complete the activity only during the final 25% of its planned duration'**
  String get activityCompleteTooEarly;

  /// No description provided for @activityCompleteNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This activity cannot be completed right now'**
  String get activityCompleteNotAllowed;

  /// No description provided for @activityCompleteAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This activity is already completed'**
  String get activityCompleteAlreadyCompleted;

  /// No description provided for @activityCompleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete this activity early?'**
  String get activityCompleteConfirmTitle;

  /// No description provided for @activityCompleteConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'The activity will end earlier than planned. Add a reason so participants understand why it finished ahead of schedule.'**
  String get activityCompleteConfirmDescription;

  /// No description provided for @activityCompleteReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Early completion reason'**
  String get activityCompleteReasonLabel;

  /// No description provided for @activityCompleteReasonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: the program finished earlier than expected'**
  String get activityCompleteReasonPlaceholder;

  /// No description provided for @activityCompleteReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason for early completion'**
  String get activityCompleteReasonRequired;

  /// No description provided for @activityCompleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm completion'**
  String get activityCompleteConfirmButton;

  /// No description provided for @activityCompleteCancelInsteadTitle.
  ///
  /// In en, this message translates to:
  /// **'This action will cancel the activity'**
  String get activityCompleteCancelInsteadTitle;

  /// No description provided for @activityCompleteCancelInsteadDescription.
  ///
  /// In en, this message translates to:
  /// **'There is still too much time left before the planned end. If you continue now, participants will see the activity as cancelled, not completed. Add a cancellation reason.'**
  String get activityCompleteCancelInsteadDescription;

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

  /// No description provided for @activityInviteFriendsButton.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get activityInviteFriendsButton;

  /// No description provided for @activityInviteFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get activityInviteFriendsTitle;

  /// No description provided for @activityInviteFriendsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get activityInviteFriendsSearchHint;

  /// No description provided for @activityInviteFriendsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends to invite'**
  String get activityInviteFriendsEmptyTitle;

  /// No description provided for @activityInviteFriendsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add friends or try another search.'**
  String get activityInviteFriendsEmptySubtitle;

  /// No description provided for @activityInviteFriendsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load friends'**
  String get activityInviteFriendsLoadFailed;

  /// No description provided for @activityInviteFriendsRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get activityInviteFriendsRetryHint;

  /// No description provided for @activityInviteFriendsSend.
  ///
  /// In en, this message translates to:
  /// **'Invite ({count})'**
  String activityInviteFriendsSend(int count);

  /// No description provided for @activityInviteFriendsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitations sent'**
  String get activityInviteFriendsSuccess;

  /// No description provided for @activityInviteFriendsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send invitations'**
  String get activityInviteFriendsFailed;

  /// No description provided for @activityInviteFriendsAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to invite friends'**
  String get activityInviteFriendsAuthRequired;

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
  /// **'Inflap Host'**
  String get activityDetailsHostFallbackName;

  /// No description provided for @activityPaymentScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'INFLAP CHECKOUT'**
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

  /// No description provided for @activityPaymentMockNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sandbox checkout'**
  String get activityPaymentMockNoticeTitle;

  /// No description provided for @activityPaymentMockNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Real payments are not connected yet. This screen only simulates a successful payment so the activity flow can be tested end to end.'**
  String get activityPaymentMockNoticeBody;

  /// No description provided for @activityPaymentSandboxMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Sandbox confirmation'**
  String get activityPaymentSandboxMethodLabel;

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
  /// **'Inflap Member'**
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
  /// **'Confirm mock payment {amount}'**
  String activityPaymentConfirmButton(Object amount);

  /// No description provided for @activityPaymentSecureNote.
  ///
  /// In en, this message translates to:
  /// **'Secure 256-bit SSL encrypted payment'**
  String get activityPaymentSecureNote;

  /// No description provided for @activityPaymentMockSecureNote.
  ///
  /// In en, this message translates to:
  /// **'No card will be charged while payments are in sandbox mode.'**
  String get activityPaymentMockSecureNote;

  /// No description provided for @activityPaymentPayButton.
  ///
  /// In en, this message translates to:
  /// **'Mock payment'**
  String get activityPaymentPayButton;

  /// No description provided for @activityPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mock payment marked as paid'**
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

  /// No description provided for @participantStatusInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get participantStatusInvited;

  /// No description provided for @participantStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get participantStatusRequested;

  /// No description provided for @participantStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get participantStatusApproved;

  /// No description provided for @participantStatusWaitlisted.
  ///
  /// In en, this message translates to:
  /// **'Waitlisted'**
  String get participantStatusWaitlisted;

  /// No description provided for @participantStatusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get participantStatusPendingPayment;

  /// No description provided for @participantStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get participantStatusConfirmed;

  /// No description provided for @participantStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get participantStatusDeclined;

  /// No description provided for @participantStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get participantStatusCancelled;

  /// No description provided for @participantStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get participantStatusExpired;

  /// No description provided for @participantStatusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get participantStatusCheckedIn;

  /// No description provided for @participantStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No show'**
  String get participantStatusNoShow;

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
  /// **'Inflap'**
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

  /// No description provided for @servicesAllButton.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get servicesAllButton;

  /// No description provided for @homeExcursionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get homeExcursionsTitle;

  /// No description provided for @homeExcursionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose interesting routes and trips'**
  String get homeExcursionsSubtitle;

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

  /// No description provided for @homeLocationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get homeLocationSheetTitle;

  /// No description provided for @homeLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get homeLocationSelected;

  /// No description provided for @homeLocationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get homeLocationUseCurrent;

  /// No description provided for @homeLocationDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting location...'**
  String get homeLocationDetecting;

  /// No description provided for @homeLocationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get homeLocationSearchHint;

  /// No description provided for @homeLocationNoResults.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get homeLocationNoResults;

  /// No description provided for @homeLocationSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to search locations. Try again.'**
  String get homeLocationSearchFailed;

  /// No description provided for @homeLocationDetectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not detect your location. Check location permissions and try again.'**
  String get homeLocationDetectionFailed;

  /// No description provided for @homeLocationApply.
  ///
  /// In en, this message translates to:
  /// **'Apply location'**
  String get homeLocationApply;

  /// No description provided for @locationFilterCitySection.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get locationFilterCitySection;

  /// No description provided for @locationFilterAllCities.
  ///
  /// In en, this message translates to:
  /// **'All cities'**
  String get locationFilterAllCities;

  /// No description provided for @locationFilterCitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get locationFilterCitySearchHint;

  /// No description provided for @locationFilterCityNoResults.
  ///
  /// In en, this message translates to:
  /// **'City not found'**
  String get locationFilterCityNoResults;

  /// No description provided for @cityFilterEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try choosing another city in filters.'**
  String get cityFilterEmptyHint;

  /// No description provided for @homeExploringLocation.
  ///
  /// In en, this message translates to:
  /// **'{location}'**
  String homeExploringLocation(Object location);

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Activities, places, excursions...'**
  String get homeSearchHint;

  /// No description provided for @homeTopDestinations.
  ///
  /// In en, this message translates to:
  /// **'Top Destinations'**
  String get homeTopDestinations;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeTopStories.
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get homeTopStories;

  /// No description provided for @homeSmartPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get homeSmartPostsTitle;

  /// No description provided for @homeSmartPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Posts picked for you will appear here.'**
  String get homeSmartPostsEmpty;

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
  /// **'Top activities'**
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

  /// No description provided for @homeServiceActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get homeServiceActivities;

  /// No description provided for @homeServiceStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get homeServiceStories;

  /// No description provided for @homeServicePlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get homeServicePlaces;

  /// No description provided for @homeServiceCurrencyConverter.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get homeServiceCurrencyConverter;

  /// No description provided for @homeServiceStays.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get homeServiceStays;

  /// No description provided for @homeServiceDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get homeServiceDelivery;

  /// No description provided for @homeServiceTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get homeServiceTaxi;

  /// No description provided for @homePromoExclusive.
  ///
  /// In en, this message translates to:
  /// **'Exclusive'**
  String get homePromoExclusive;

  /// No description provided for @homePromoAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get homePromoAdventure;

  /// No description provided for @homePromoYachtTitle.
  ///
  /// In en, this message translates to:
  /// **'Yacht Parties'**
  String get homePromoYachtTitle;

  /// No description provided for @homePromoYachtDescription.
  ///
  /// In en, this message translates to:
  /// **'Experience luxury on the waves with our curated...'**
  String get homePromoYachtDescription;

  /// No description provided for @homePromoMountainTitle.
  ///
  /// In en, this message translates to:
  /// **'Mountain Excursions'**
  String get homePromoMountainTitle;

  /// No description provided for @homePromoMountainDescription.
  ///
  /// In en, this message translates to:
  /// **'Scale scenic routes with local experts...'**
  String get homePromoMountainDescription;

  /// No description provided for @homePromoExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homePromoExplore;

  /// No description provided for @currencyConverterTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency Converter'**
  String get currencyConverterTitle;

  /// No description provided for @currencyConverterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Convert travel prices without leaving Inflap.'**
  String get currencyConverterSubtitle;

  /// No description provided for @currencyConverterAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get currencyConverterAmountLabel;

  /// No description provided for @currencyConverterFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get currencyConverterFromLabel;

  /// No description provided for @currencyConverterToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get currencyConverterToLabel;

  /// No description provided for @currencyConverterYouSend.
  ///
  /// In en, this message translates to:
  /// **'You send'**
  String get currencyConverterYouSend;

  /// No description provided for @currencyConverterYouReceive.
  ///
  /// In en, this message translates to:
  /// **'You receive'**
  String get currencyConverterYouReceive;

  /// No description provided for @currencyConverterQuickSwitch.
  ///
  /// In en, this message translates to:
  /// **'Quick switch'**
  String get currencyConverterQuickSwitch;

  /// No description provided for @currencyConverterSelectCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get currencyConverterSelectCurrencyTitle;

  /// No description provided for @currencyConverterSearchCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyConverterSearchCurrencyHint;

  /// No description provided for @currencyConverterRecentSection.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get currencyConverterRecentSection;

  /// No description provided for @currencyConverterAllCurrenciesSection.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get currencyConverterAllCurrenciesSection;

  /// No description provided for @currencyConverterNoCurrenciesFound.
  ///
  /// In en, this message translates to:
  /// **'No currencies found'**
  String get currencyConverterNoCurrenciesFound;

  /// No description provided for @currencyConverterSwapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap currencies'**
  String get currencyConverterSwapTooltip;

  /// No description provided for @currencyConverterConvertButton.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get currencyConverterConvertButton;

  /// No description provided for @currencyConverterLoading.
  ///
  /// In en, this message translates to:
  /// **'Converting...'**
  String get currencyConverterLoading;

  /// No description provided for @currencyConverterResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get currencyConverterResultTitle;

  /// No description provided for @currencyConverterUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Rate updated {value}'**
  String currencyConverterUpdatedAt(Object value);

  /// No description provided for @currencyConverterProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider: {value}'**
  String currencyConverterProvider(Object value);

  /// No description provided for @currencyConverterStaleWarning.
  ///
  /// In en, this message translates to:
  /// **'Showing a fallback reference rate because the live provider is unavailable.'**
  String get currencyConverterStaleWarning;

  /// No description provided for @currencyConverterPopularPairs.
  ///
  /// In en, this message translates to:
  /// **'Popular pairs'**
  String get currencyConverterPopularPairs;

  /// No description provided for @currencyConverterInfoNotice.
  ///
  /// In en, this message translates to:
  /// **'Rates are informational and may differ from payment provider rates during checkout.'**
  String get currencyConverterInfoNotice;

  /// No description provided for @currencyConverterAmountValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get currencyConverterAmountValidation;

  /// No description provided for @currencyConverterLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not convert right now. Check the connection and try again.'**
  String get currencyConverterLoadFailed;

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

  /// No description provided for @feedNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedNavLabel;

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

  /// No description provided for @mapAttributionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Map data sources'**
  String get mapAttributionSheetTitle;

  /// No description provided for @mapAttributionSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inflap shows map tiles built from open map data. Attribution and license details are available below.'**
  String get mapAttributionSheetSubtitle;

  /// No description provided for @mapAttributionStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Map style'**
  String get mapAttributionStyleLabel;

  /// No description provided for @mapAttributionTilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Tiles and schema'**
  String get mapAttributionTilesLabel;

  /// No description provided for @mapAttributionDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Map data'**
  String get mapAttributionDataLabel;

  /// No description provided for @mapAttributionLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get mapAttributionLicenseLabel;

  /// No description provided for @mapAttributionOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get mapAttributionOpenLink;

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

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedTitle;

  /// No description provided for @feedTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get feedTabForYou;

  /// No description provided for @feedTabFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedTabFollowing;

  /// No description provided for @feedStoriesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get feedStoriesSectionTitle;

  /// No description provided for @feedCreateStoryAction.
  ///
  /// In en, this message translates to:
  /// **'Your story'**
  String get feedCreateStoryAction;

  /// No description provided for @storyCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to story'**
  String get storyCaptureTitle;

  /// No description provided for @storyCapturePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get storyCapturePreviewTitle;

  /// No description provided for @storyCaptureCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storyCaptureCloseLabel;

  /// No description provided for @storyCaptureSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get storyCaptureSettingsLabel;

  /// No description provided for @storyCaptureGalleryAction.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get storyCaptureGalleryAction;

  /// No description provided for @storyCapturePhotoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get storyCapturePhotoFromGallery;

  /// No description provided for @storyCaptureVideoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose video'**
  String get storyCaptureVideoFromGallery;

  /// No description provided for @storyCaptureCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable. Check permissions and try again.'**
  String get storyCaptureCameraUnavailable;

  /// No description provided for @storyCapturePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera or microphone access is denied.'**
  String get storyCapturePermissionDenied;

  /// No description provided for @storyCaptureCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not capture the story. Try again.'**
  String get storyCaptureCaptureFailed;

  /// No description provided for @storyCaptureFlashOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get storyCaptureFlashOffLabel;

  /// No description provided for @storyCaptureFlashAutoLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto flash'**
  String get storyCaptureFlashAutoLabel;

  /// No description provided for @storyCaptureFlashOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get storyCaptureFlashOnLabel;

  /// No description provided for @storyCaptureFlashUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Flash is not available for this camera.'**
  String get storyCaptureFlashUnsupported;

  /// No description provided for @storyCapturePhotoMode.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get storyCapturePhotoMode;

  /// No description provided for @storyCaptureVideoMode.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get storyCaptureVideoMode;

  /// No description provided for @storyCaptureCaptureButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get storyCaptureCaptureButtonLabel;

  /// No description provided for @storyCaptureRecordButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get storyCaptureRecordButtonLabel;

  /// No description provided for @storyCaptureStopButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get storyCaptureStopButtonLabel;

  /// No description provided for @storyCaptureFlipCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get storyCaptureFlipCameraLabel;

  /// No description provided for @storyCaptureCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get storyCaptureCaptionHint;

  /// No description provided for @storyCaptureRetakeAction.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get storyCaptureRetakeAction;

  /// No description provided for @storyCapturePublishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get storyCapturePublishAction;

  /// No description provided for @storyCapturePublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get storyCapturePublishing;

  /// No description provided for @storyCapturePublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish the story. Try again.'**
  String get storyCapturePublishFailed;

  /// No description provided for @storyReplyInputHint.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get storyReplyInputHint;

  /// No description provided for @storyReplySendAction.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get storyReplySendAction;

  /// No description provided for @storyReplySentMessage.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get storyReplySentMessage;

  /// No description provided for @storyReplySendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send reply. Try again.'**
  String get storyReplySendFailed;

  /// No description provided for @storyLikeAction.
  ///
  /// In en, this message translates to:
  /// **'Like story'**
  String get storyLikeAction;

  /// No description provided for @storyLikeSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not like the story. Try again.'**
  String get storyLikeSendFailed;

  /// No description provided for @storyCaptureDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'My story'**
  String get storyCaptureDefaultTitle;

  /// No description provided for @storyCaptureDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'New story'**
  String get storyCaptureDefaultBody;

  /// No description provided for @storyCaptureDefaultPlace.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get storyCaptureDefaultPlace;

  /// No description provided for @storyCapturePublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Story published'**
  String get storyCapturePublishedMessage;

  /// No description provided for @feedSuggestedCommunitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Communities to follow'**
  String get feedSuggestedCommunitiesTitle;

  /// No description provided for @feedJoinCommunityAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get feedJoinCommunityAction;

  /// No description provided for @feedCommunityJoinedAction.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedCommunityJoinedAction;

  /// No description provided for @feedCommunityModerationAction.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get feedCommunityModerationAction;

  /// No description provided for @feedCommunityActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the subscription. Try again.'**
  String get feedCommunityActionFailed;

  /// No description provided for @feedCommunityMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String feedCommunityMembersLabel(String count);

  /// No description provided for @feedMySubscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My subscriptions'**
  String get feedMySubscriptionsTitle;

  /// No description provided for @feedMySubscriptionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{communities} communities · {people} people'**
  String feedMySubscriptionsSummary(int communities, int people);

  /// No description provided for @feedMySubscriptionsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get feedMySubscriptionsViewAll;

  /// No description provided for @feedMySubscriptionsCommunitiesTab.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get feedMySubscriptionsCommunitiesTab;

  /// No description provided for @feedMySubscriptionsPeopleTab.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get feedMySubscriptionsPeopleTab;

  /// No description provided for @feedMySubscriptionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get feedMySubscriptionsSearchHint;

  /// No description provided for @feedMySubscriptionsSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Communities, friends, and followed people you keep close in the feed.'**
  String get feedMySubscriptionsSheetSubtitle;

  /// No description provided for @feedMySubscriptionsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedMySubscriptionsFilterAll;

  /// No description provided for @feedMySubscriptionsFilterStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Subscription status'**
  String get feedMySubscriptionsFilterStatusSection;

  /// No description provided for @feedMySubscriptionsFilterPeopleSection.
  ///
  /// In en, this message translates to:
  /// **'Connection type'**
  String get feedMySubscriptionsFilterPeopleSection;

  /// No description provided for @feedMySubscriptionsFilterCommunityActivitySection.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get feedMySubscriptionsFilterCommunityActivitySection;

  /// No description provided for @feedMySubscriptionsFilterCommunityTopicSection.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get feedMySubscriptionsFilterCommunityTopicSection;

  /// No description provided for @feedMySubscriptionsFilterPeopleConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get feedMySubscriptionsFilterPeopleConnectionSection;

  /// No description provided for @feedMySubscriptionsFilterPeopleActivitySection.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get feedMySubscriptionsFilterPeopleActivitySection;

  /// No description provided for @feedMySubscriptionsFilterSortSection.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get feedMySubscriptionsFilterSortSection;

  /// No description provided for @feedMySubscriptionsFilterSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get feedMySubscriptionsFilterSubscribed;

  /// No description provided for @feedMySubscriptionsFilterUnsubscribed.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribed'**
  String get feedMySubscriptionsFilterUnsubscribed;

  /// No description provided for @feedMySubscriptionsFilterCurrentCity.
  ///
  /// In en, this message translates to:
  /// **'My city'**
  String get feedMySubscriptionsFilterCurrentCity;

  /// No description provided for @feedMySubscriptionsFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Has posts'**
  String get feedMySubscriptionsFilterActive;

  /// No description provided for @feedMySubscriptionsFilterPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get feedMySubscriptionsFilterPopular;

  /// No description provided for @feedMySubscriptionsFilterFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get feedMySubscriptionsFilterFriends;

  /// No description provided for @feedMySubscriptionsFilterFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedMySubscriptionsFilterFollowing;

  /// No description provided for @feedMySubscriptionsFilterOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get feedMySubscriptionsFilterOnline;

  /// No description provided for @feedMySubscriptionsSortRelevant.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get feedMySubscriptionsSortRelevant;

  /// No description provided for @feedMySubscriptionsSortMostActive.
  ///
  /// In en, this message translates to:
  /// **'Most active'**
  String get feedMySubscriptionsSortMostActive;

  /// No description provided for @feedMySubscriptionsSortMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most followed'**
  String get feedMySubscriptionsSortMostPopular;

  /// No description provided for @feedMySubscriptionsSortName.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get feedMySubscriptionsSortName;

  /// No description provided for @feedMySubscriptionsSortOnlineFirst.
  ///
  /// In en, this message translates to:
  /// **'Online first'**
  String get feedMySubscriptionsSortOnlineFirst;

  /// No description provided for @feedPostSortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get feedPostSortRecommended;

  /// No description provided for @feedPostSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get feedPostSortNewest;

  /// No description provided for @feedPostSortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get feedPostSortPopular;

  /// No description provided for @feedPostSortDiscussed.
  ///
  /// In en, this message translates to:
  /// **'Discussed'**
  String get feedPostSortDiscussed;

  /// No description provided for @feedPostLikeAction.
  ///
  /// In en, this message translates to:
  /// **'Like post'**
  String get feedPostLikeAction;

  /// No description provided for @feedPostUnlikeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove like'**
  String get feedPostUnlikeAction;

  /// No description provided for @feedPostShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share post'**
  String get feedPostShareAction;

  /// No description provided for @feedPostMoreActions.
  ///
  /// In en, this message translates to:
  /// **'Post actions'**
  String get feedPostMoreActions;

  /// No description provided for @feedPostHideAction.
  ///
  /// In en, this message translates to:
  /// **'Hide post'**
  String get feedPostHideAction;

  /// No description provided for @feedPostNotInterestedAction.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get feedPostNotInterestedAction;

  /// No description provided for @feedPostActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the post. Try again.'**
  String get feedPostActionFailed;

  /// No description provided for @feedMySubscriptionsApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get feedMySubscriptionsApplyFilters;

  /// No description provided for @feedMySubscriptionsShowCommunitiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Show {count} community} other{Show {count} communities}}'**
  String feedMySubscriptionsShowCommunitiesCount(num count);

  /// No description provided for @feedMySubscriptionsShowPeopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Show {count} person} other{Show {count} people}}'**
  String feedMySubscriptionsShowPeopleCount(num count);

  /// No description provided for @feedMySubscriptionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions match these filters.'**
  String get feedMySubscriptionsEmptyMessage;

  /// No description provided for @feedMySubscriptionsFriendBadge.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get feedMySubscriptionsFriendBadge;

  /// No description provided for @feedMySubscriptionsFollowingBadge.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedMySubscriptionsFollowingBadge;

  /// No description provided for @feedMySubscriptionsOnlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get feedMySubscriptionsOnlineBadge;

  /// No description provided for @feedMySubscriptionsUnknownPerson.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get feedMySubscriptionsUnknownPerson;

  /// No description provided for @feedSystemPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Official updates'**
  String get feedSystemPostsTitle;

  /// No description provided for @feedSystemPostsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get feedSystemPostsViewAll;

  /// No description provided for @feedSystemPostsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Official posts'**
  String get feedSystemPostsSheetTitle;

  /// No description provided for @communityDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communityDiscoveryTitle;

  /// No description provided for @communityDiscoveryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No communities yet'**
  String get communityDiscoveryEmptyTitle;

  /// No description provided for @communityDiscoveryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Official communities will appear here as they launch.'**
  String get communityDiscoveryEmptyMessage;

  /// No description provided for @communityDiscoveryLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load communities'**
  String get communityDiscoveryLoadFailedTitle;

  /// No description provided for @communityDiscoveryLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get communityDiscoveryLoadFailedMessage;

  /// No description provided for @communityDiscoverySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communityDiscoverySearchHint;

  /// No description provided for @communityDiscoveryFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get communityDiscoveryFiltersTitle;

  /// No description provided for @communityDiscoveryShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show communities'**
  String get communityDiscoveryShowResults;

  /// No description provided for @communityDiscoveryShowResultsCount.
  ///
  /// In en, this message translates to:
  /// **'Show {count, plural, =0{0 communities} =1{1 community} other{{count} communities}}'**
  String communityDiscoveryShowResultsCount(num count);

  /// No description provided for @communityDiscoveryRequiredLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a country and city to find active local communities.'**
  String get communityDiscoveryRequiredLocationMessage;

  /// No description provided for @communityDiscoveryTopicSection.
  ///
  /// In en, this message translates to:
  /// **'Community type'**
  String get communityDiscoveryTopicSection;

  /// No description provided for @communityDiscoveryTopicAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityDiscoveryTopicAll;

  /// No description provided for @communityDiscoveryTopicTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get communityDiscoveryTopicTravel;

  /// No description provided for @communityDiscoveryTopicCity.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get communityDiscoveryTopicCity;

  /// No description provided for @communityDiscoveryTopicGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides and tours'**
  String get communityDiscoveryTopicGuides;

  /// No description provided for @communityDiscoveryTopicAppNews.
  ///
  /// In en, this message translates to:
  /// **'Inflap news'**
  String get communityDiscoveryTopicAppNews;

  /// No description provided for @communityTopicLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get communityTopicLanguages;

  /// No description provided for @communityTopicHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get communityTopicHousing;

  /// No description provided for @communityTopicTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get communityTopicTransport;

  /// No description provided for @communityTopicSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get communityTopicSports;

  /// No description provided for @communityTopicOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Trips and outdoors'**
  String get communityTopicOutdoor;

  /// No description provided for @communityTopicHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies and workshops'**
  String get communityTopicHobbies;

  /// No description provided for @communityTopicWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get communityTopicWellness;

  /// No description provided for @communityTopicPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get communityTopicPets;

  /// No description provided for @communityTopicCityLife.
  ///
  /// In en, this message translates to:
  /// **'City life'**
  String get communityTopicCityLife;

  /// No description provided for @communityTopicContent.
  ///
  /// In en, this message translates to:
  /// **'News and guides'**
  String get communityTopicContent;

  /// No description provided for @communityTopicFamily.
  ///
  /// In en, this message translates to:
  /// **'Families'**
  String get communityTopicFamily;

  /// No description provided for @communityTopicGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get communityTopicGeneral;

  /// No description provided for @communityProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityProfileTitle;

  /// No description provided for @communityProfileActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Community actions'**
  String get communityProfileActionsTooltip;

  /// No description provided for @communityProfileCreatePostAction.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get communityProfileCreatePostAction;

  /// No description provided for @communityPostModeSelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Publishing mode'**
  String get communityPostModeSelectorLabel;

  /// No description provided for @communityPostModeArticle.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get communityPostModeArticle;

  /// No description provided for @communityPostModeQuickPost.
  ///
  /// In en, this message translates to:
  /// **'Discussions'**
  String get communityPostModeQuickPost;

  /// No description provided for @communityPostModeListing.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get communityPostModeListing;

  /// No description provided for @communityPostModeEventAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get communityPostModeEventAnnouncement;

  /// No description provided for @communityPostModeQuestionAnswer.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get communityPostModeQuestionAnswer;

  /// No description provided for @communityPostModeTripPlan.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get communityPostModeTripPlan;

  /// No description provided for @communityProfileUnfollowConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfollow community?'**
  String get communityProfileUnfollowConfirmTitle;

  /// No description provided for @communityProfileRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Community rules'**
  String get communityProfileRulesTitle;

  /// No description provided for @communityProfilePostsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get communityProfilePostsSectionTitle;

  /// No description provided for @communityProfileNoPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get communityProfileNoPostsTitle;

  /// No description provided for @communityProfileNoPostsMessage.
  ///
  /// In en, this message translates to:
  /// **'New posts from this community will appear here.'**
  String get communityProfileNoPostsMessage;

  /// No description provided for @communityProfilePostsLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load posts'**
  String get communityProfilePostsLoadFailedTitle;

  /// No description provided for @communityProfilePostsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} posts'**
  String communityProfilePostsLabel(String count);

  /// No description provided for @communityProfileLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load community'**
  String get communityProfileLoadFailedTitle;

  /// No description provided for @communityProfileLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get communityProfileLoadFailedMessage;

  /// No description provided for @communityTrustReportAction.
  ///
  /// In en, this message translates to:
  /// **'Report community'**
  String get communityTrustReportAction;

  /// No description provided for @communityTrustMuteAction.
  ///
  /// In en, this message translates to:
  /// **'Mute community'**
  String get communityTrustMuteAction;

  /// No description provided for @communityTrustUnmuteAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute community'**
  String get communityTrustUnmuteAction;

  /// No description provided for @communityTrustBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Posting blocked'**
  String get communityTrustBlockedTitle;

  /// No description provided for @communityTrustBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'You cannot post in this community until moderators lift the restriction.'**
  String get communityTrustBlockedMessage;

  /// No description provided for @communityTrustMutedTitle.
  ///
  /// In en, this message translates to:
  /// **'Community muted'**
  String get communityTrustMutedTitle;

  /// No description provided for @communityTrustMutedMessage.
  ///
  /// In en, this message translates to:
  /// **'This community is muted in your feed. You can unmute it anytime.'**
  String get communityTrustMutedMessage;

  /// No description provided for @communityTrustAppealPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Appeal in review'**
  String get communityTrustAppealPendingTitle;

  /// No description provided for @communityTrustAppealPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Moderators are reviewing your appeal for this community.'**
  String get communityTrustAppealPendingMessage;

  /// No description provided for @communityTrustAppealRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Appeal rejected'**
  String get communityTrustAppealRejectedTitle;

  /// No description provided for @communityTrustAppealRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'The restriction remains active after moderator review.'**
  String get communityTrustAppealRejectedMessage;

  /// No description provided for @communityTrustAppealAction.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get communityTrustAppealAction;

  /// No description provided for @communityTrustAppealMessage.
  ///
  /// In en, this message translates to:
  /// **'Please review my community restriction again.'**
  String get communityTrustAppealMessage;

  /// No description provided for @communityTrustReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Community sent to moderation.'**
  String get communityTrustReportSubmitted;

  /// No description provided for @communityTrustMutedSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Community muted.'**
  String get communityTrustMutedSubmitted;

  /// No description provided for @communityTrustUnmutedSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Community unmuted.'**
  String get communityTrustUnmutedSubmitted;

  /// No description provided for @communityTrustAppealSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Appeal sent to moderators.'**
  String get communityTrustAppealSubmitted;

  /// No description provided for @communityTrustActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This trust action is not available yet.'**
  String get communityTrustActionUnavailable;

  /// No description provided for @communityTrustActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the trust action. Try again.'**
  String get communityTrustActionFailed;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No feed items yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Follow travelers and communities to shape your feed.'**
  String get feedEmptyMessage;

  /// No description provided for @feedLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load feed'**
  String get feedLoadFailedTitle;

  /// No description provided for @feedLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get feedLoadFailedMessage;

  /// No description provided for @feedRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get feedRetryAction;

  /// No description provided for @communityModerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation queue'**
  String get communityModerationTitle;

  /// No description provided for @communityModerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String communityModerationSubtitle(int count);

  /// No description provided for @communityModerationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts waiting'**
  String get communityModerationEmptyTitle;

  /// No description provided for @communityModerationEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'New community posts that need review will appear here.'**
  String get communityModerationEmptyMessage;

  /// No description provided for @communityModerationLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load moderation queue'**
  String get communityModerationLoadFailedTitle;

  /// No description provided for @communityModerationLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get communityModerationLoadFailedMessage;

  /// No description provided for @communityModerationApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get communityModerationApproveAction;

  /// No description provided for @communityModerationRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get communityModerationRejectAction;

  /// No description provided for @communityModerationHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get communityModerationHistoryAction;

  /// No description provided for @communityModerationApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Post approved'**
  String get communityModerationApprovedMessage;

  /// No description provided for @communityModerationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Post rejected'**
  String get communityModerationRejectedMessage;

  /// No description provided for @communityModerationActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this post. Try again.'**
  String get communityModerationActionFailed;

  /// No description provided for @communityModerationDecisionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision history'**
  String get communityModerationDecisionHistoryTitle;

  /// No description provided for @communityModerationDecisionHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No moderation decisions yet.'**
  String get communityModerationDecisionHistoryEmpty;

  /// No description provided for @communityModerationDecisionHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load decision history.'**
  String get communityModerationDecisionHistoryFailed;

  /// No description provided for @communityModerationRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get communityModerationRejectReasonLabel;

  /// No description provided for @communityModerationRejectConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Reject post'**
  String get communityModerationRejectConfirmAction;

  /// No description provided for @communityModerationRejectCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get communityModerationRejectCancelAction;

  /// No description provided for @communityMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communityMembersTitle;

  /// No description provided for @communityMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage access and roles'**
  String get communityMembersSubtitle;

  /// No description provided for @communityMembersAction.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communityMembersAction;

  /// No description provided for @communityMembersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get communityMembersEmptyTitle;

  /// No description provided for @communityMembersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Members matching the selected filters will appear here.'**
  String get communityMembersEmptyMessage;

  /// No description provided for @communityMembersLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load members'**
  String get communityMembersLoadFailedTitle;

  /// No description provided for @communityMembersLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get communityMembersLoadFailedMessage;

  /// No description provided for @communityMembersRoleFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get communityMembersRoleFilterLabel;

  /// No description provided for @communityMembersStatusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get communityMembersStatusFilterLabel;

  /// No description provided for @communityMembersAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityMembersAllFilter;

  /// No description provided for @communityMembersActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get communityMembersActiveStatus;

  /// No description provided for @communityMembersMutedStatus.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get communityMembersMutedStatus;

  /// No description provided for @communityMembersBannedStatus.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get communityMembersBannedStatus;

  /// No description provided for @communityMembersLeftStatus.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get communityMembersLeftStatus;

  /// No description provided for @communityMembersTrustedRole.
  ///
  /// In en, this message translates to:
  /// **'Trusted member'**
  String get communityMembersTrustedRole;

  /// No description provided for @communityMembersModeratorRole.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get communityMembersModeratorRole;

  /// No description provided for @communityMembersAdminRole.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get communityMembersAdminRole;

  /// No description provided for @communityMembersMemberRole.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get communityMembersMemberRole;

  /// No description provided for @communityMembersChangeRoleAction.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get communityMembersChangeRoleAction;

  /// No description provided for @communityMembersRoleHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Role history'**
  String get communityMembersRoleHistoryAction;

  /// No description provided for @communityMembersRoleHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Role history'**
  String get communityMembersRoleHistoryTitle;

  /// No description provided for @communityMembersRoleHistoryChangedBy.
  ///
  /// In en, this message translates to:
  /// **'Changed by'**
  String get communityMembersRoleHistoryChangedBy;

  /// No description provided for @communityMembersRoleHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No role changes'**
  String get communityMembersRoleHistoryEmptyTitle;

  /// No description provided for @communityMembersRoleHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Role updates for this member will appear here.'**
  String get communityMembersRoleHistoryEmptyMessage;

  /// No description provided for @communityMembersRoleHistoryLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load role history'**
  String get communityMembersRoleHistoryLoadFailedTitle;

  /// No description provided for @communityMembersRoleHistoryLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get communityMembersRoleHistoryLoadFailedMessage;

  /// No description provided for @communityMembersChangeStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get communityMembersChangeStatusAction;

  /// No description provided for @communityMembersMuteAction.
  ///
  /// In en, this message translates to:
  /// **'Mute member'**
  String get communityMembersMuteAction;

  /// No description provided for @communityMembersBanAction.
  ///
  /// In en, this message translates to:
  /// **'Ban member'**
  String get communityMembersBanAction;

  /// No description provided for @communityMembersRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get communityMembersRemoveAction;

  /// No description provided for @communityMembersRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore member'**
  String get communityMembersRestoreAction;

  /// No description provided for @communityMembersStatusUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get communityMembersStatusUpdatedMessage;

  /// No description provided for @communityMembersStatusUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this member status. Try again.'**
  String get communityMembersStatusUpdateFailed;

  /// No description provided for @communityMembersRoleUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get communityMembersRoleUpdatedMessage;

  /// No description provided for @communityMembersRoleUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this member. Try again.'**
  String get communityMembersRoleUpdateFailed;

  /// No description provided for @mapNearbyPlacesLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby places'**
  String get mapNearbyPlacesLabel;

  /// No description provided for @mapSearchingNearbyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Looking for nearby venues and places'**
  String get mapSearchingNearbyPlaces;

  /// No description provided for @mapPlacesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load nearby places'**
  String get mapPlacesLoadFailed;

  /// No description provided for @mapNoPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'No nearby places found'**
  String get mapNoPlacesTitle;

  /// No description provided for @mapNoPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move the map or refresh your location to explore other nearby venues and points of interest.'**
  String get mapNoPlacesSubtitle;

  /// No description provided for @mapTapPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a marker or place card to preview it and copy its link.'**
  String get mapTapPlaceHint;

  /// No description provided for @mapCopyPlaceLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get mapCopyPlaceLink;

  /// No description provided for @mapPlaceLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Place link copied'**
  String get mapPlaceLinkCopied;

  /// No description provided for @mapUsingFallbackLocation.
  ///
  /// In en, this message translates to:
  /// **'Showing the map from a fallback location'**
  String get mapUsingFallbackLocation;

  /// No description provided for @mapDistancePending.
  ///
  /// In en, this message translates to:
  /// **'Calculating distance'**
  String get mapDistancePending;

  /// No description provided for @mapPlacesCount.
  ///
  /// In en, this message translates to:
  /// **'Places found: {count}'**
  String mapPlacesCount(int count);

  /// No description provided for @mapActivitiesCount.
  ///
  /// In en, this message translates to:
  /// **'Activities: {count}'**
  String mapActivitiesCount(int count);

  /// No description provided for @mapTapActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an activity marker to preview it and open details.'**
  String get mapTapActivityHint;

  /// No description provided for @mapExternalOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the route in an external map app.'**
  String get mapExternalOpenFailed;

  /// No description provided for @routeSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel time'**
  String get routeSummaryTitle;

  /// No description provided for @routeSummaryDuration.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get routeSummaryDuration;

  /// No description provided for @routeSummaryDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get routeSummaryDistance;

  /// No description provided for @routeDurationMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String routeDurationMinutesShort(int minutes);

  /// No description provided for @routeDistanceMetersShort.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String routeDistanceMetersShort(int meters);

  /// No description provided for @routeDistanceKilometersShort.
  ///
  /// In en, this message translates to:
  /// **'{kilometers} km'**
  String routeDistanceKilometersShort(String kilometers);

  /// No description provided for @routeTravelTimeDistanceShort.
  ///
  /// In en, this message translates to:
  /// **'{duration} · {distance}'**
  String routeTravelTimeDistanceShort(Object duration, Object distance);

  /// No description provided for @routeStopSemantic.
  ///
  /// In en, this message translates to:
  /// **'Route stop {order}'**
  String routeStopSemantic(int order);

  /// No description provided for @userRoutesSaveRoute.
  ///
  /// In en, this message translates to:
  /// **'Save route'**
  String get userRoutesSaveRoute;

  /// No description provided for @userRoutesRouteSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get userRoutesRouteSaved;

  /// No description provided for @userRoutesSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Route saved'**
  String get userRoutesSaveSuccess;

  /// No description provided for @userRoutesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save route'**
  String get userRoutesSaveFailed;

  /// No description provided for @userRoutesDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved route'**
  String get userRoutesDefaultTitle;

  /// No description provided for @userRoutesDefaultTitleTo.
  ///
  /// In en, this message translates to:
  /// **'Route to {destination}'**
  String userRoutesDefaultTitleTo(Object destination);

  /// No description provided for @mapRouteBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Create route'**
  String get mapRouteBuilderTitle;

  /// No description provided for @mapRouteBuilderHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to add stops in order.'**
  String get mapRouteBuilderHint;

  /// No description provided for @mapRouteBuilderBuildRoute.
  ///
  /// In en, this message translates to:
  /// **'Build route'**
  String get mapRouteBuilderBuildRoute;

  /// No description provided for @mapRouteBuilderMinPoints.
  ///
  /// In en, this message translates to:
  /// **'Add at least two points to build a route.'**
  String get mapRouteBuilderMinPoints;

  /// No description provided for @mapRouteBuilderClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapRouteBuilderClear;

  /// No description provided for @mapRouteBuilderRemoveLast.
  ///
  /// In en, this message translates to:
  /// **'Remove last'**
  String get mapRouteBuilderRemoveLast;

  /// No description provided for @mapRouteBuilderPointName.
  ///
  /// In en, this message translates to:
  /// **'Point {order}'**
  String mapRouteBuilderPointName(int order);

  /// No description provided for @userRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get userRoutesTitle;

  /// No description provided for @userRoutesPublicTab.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get userRoutesPublicTab;

  /// No description provided for @userRoutesMineTab.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get userRoutesMineTab;

  /// No description provided for @userRoutesSavedTab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get userRoutesSavedTab;

  /// No description provided for @userRoutesPublicEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No public routes yet'**
  String get userRoutesPublicEmptyTitle;

  /// No description provided for @userRoutesPublicEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved public walks and city plans will appear here.'**
  String get userRoutesPublicEmptySubtitle;

  /// No description provided for @userRoutesMineEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No routes yet'**
  String get userRoutesMineEmptyTitle;

  /// No description provided for @userRoutesMineEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a route on the map and save it to keep your own collection.'**
  String get userRoutesMineEmptySubtitle;

  /// No description provided for @userRoutesSavedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved routes'**
  String get userRoutesSavedEmptyTitle;

  /// No description provided for @userRoutesSavedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark routes from other travelers to find them here.'**
  String get userRoutesSavedEmptySubtitle;

  /// No description provided for @userRoutesLoginRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use your routes'**
  String get userRoutesLoginRequiredTitle;

  /// No description provided for @userRoutesLoginRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your private and saved routes are linked to your Inflap account.'**
  String get userRoutesLoginRequiredSubtitle;

  /// No description provided for @userRoutesLoginRequiredButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get userRoutesLoginRequiredButton;

  /// No description provided for @userRoutesStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String userRoutesStopsCount(int count);

  /// No description provided for @userRoutesVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get userRoutesVisibilityPrivate;

  /// No description provided for @userRoutesVisibilityUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Link only'**
  String get userRoutesVisibilityUnlisted;

  /// No description provided for @userRoutesVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get userRoutesVisibilityPublic;

  /// No description provided for @userRoutesOpenOnMap.
  ///
  /// In en, this message translates to:
  /// **'Open on map'**
  String get userRoutesOpenOnMap;

  /// No description provided for @userRoutesCopyRoute.
  ///
  /// In en, this message translates to:
  /// **'Copy route'**
  String get userRoutesCopyRoute;

  /// No description provided for @userRoutesCopied.
  ///
  /// In en, this message translates to:
  /// **'Route copied to your routes'**
  String get userRoutesCopied;

  /// No description provided for @userRoutesEditRoute.
  ///
  /// In en, this message translates to:
  /// **'Edit route'**
  String get userRoutesEditRoute;

  /// No description provided for @userRoutesEditTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Route title'**
  String get userRoutesEditTitleLabel;

  /// No description provided for @userRoutesEditDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get userRoutesEditDescriptionLabel;

  /// No description provided for @userRoutesEditVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get userRoutesEditVisibilityLabel;

  /// No description provided for @userRoutesEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get userRoutesEditSave;

  /// No description provided for @userRoutesUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Route updated'**
  String get userRoutesUpdateSuccess;

  /// No description provided for @userRoutesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update route'**
  String get userRoutesUpdateFailed;

  /// No description provided for @userRoutesShareRoute.
  ///
  /// In en, this message translates to:
  /// **'Share route'**
  String get userRoutesShareRoute;

  /// No description provided for @userRoutesShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Route link copied'**
  String get userRoutesShareCopied;

  /// No description provided for @userRoutesEditStops.
  ///
  /// In en, this message translates to:
  /// **'Edit stops'**
  String get userRoutesEditStops;

  /// No description provided for @userRoutesEditStopsHint.
  ///
  /// In en, this message translates to:
  /// **'Reorder stops or rename them. Inflap will rebuild the route before saving.'**
  String get userRoutesEditStopsHint;

  /// No description provided for @userRoutesEditStopNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop name'**
  String get userRoutesEditStopNameLabel;

  /// No description provided for @userRoutesEditStopNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get userRoutesEditStopNoteLabel;

  /// No description provided for @userRoutesMoveStopUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get userRoutesMoveStopUp;

  /// No description provided for @userRoutesMoveStopDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get userRoutesMoveStopDown;

  /// No description provided for @userRoutesRebuildAndSave.
  ///
  /// In en, this message translates to:
  /// **'Rebuild and save'**
  String get userRoutesRebuildAndSave;

  /// No description provided for @userRoutesEditPointsMinStops.
  ///
  /// In en, this message translates to:
  /// **'Keep at least two stops in the route.'**
  String get userRoutesEditPointsMinStops;

  /// No description provided for @userRoutesRebuildFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not rebuild route'**
  String get userRoutesRebuildFailed;

  /// No description provided for @userRoutesStopsUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Route stops updated'**
  String get userRoutesStopsUpdateSuccess;

  /// No description provided for @userRoutesUnsaveRoute.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get userRoutesUnsaveRoute;

  /// No description provided for @userRoutesStopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get userRoutesStopsTitle;

  /// No description provided for @routeProfileTouristWalk.
  ///
  /// In en, this message translates to:
  /// **'Tourist walk'**
  String get routeProfileTouristWalk;

  /// No description provided for @routeProfileFastWalk.
  ///
  /// In en, this message translates to:
  /// **'Fast walk'**
  String get routeProfileFastWalk;

  /// No description provided for @routeProfileBikeCity.
  ///
  /// In en, this message translates to:
  /// **'City bike'**
  String get routeProfileBikeCity;

  /// No description provided for @routeProfileCarStandard.
  ///
  /// In en, this message translates to:
  /// **'Car route'**
  String get routeProfileCarStandard;

  /// No description provided for @routeProfileGuideRoute.
  ///
  /// In en, this message translates to:
  /// **'Guide route'**
  String get routeProfileGuideRoute;

  /// No description provided for @routeProfileDayPlan.
  ///
  /// In en, this message translates to:
  /// **'Day plan'**
  String get routeProfileDayPlan;

  /// No description provided for @routeProfileTransit.
  ///
  /// In en, this message translates to:
  /// **'Public transport'**
  String get routeProfileTransit;

  /// No description provided for @routeProfileTouristWalkShort.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get routeProfileTouristWalkShort;

  /// No description provided for @routeProfileFastWalkShort.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get routeProfileFastWalkShort;

  /// No description provided for @routeProfileBikeCityShort.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get routeProfileBikeCityShort;

  /// No description provided for @routeProfileCarStandardShort.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get routeProfileCarStandardShort;

  /// No description provided for @routeProfileGuideRouteShort.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get routeProfileGuideRouteShort;

  /// No description provided for @routeProfileDayPlanShort.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get routeProfileDayPlanShort;

  /// No description provided for @routeProfileTransitShort.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get routeProfileTransitShort;

  /// No description provided for @placesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover places'**
  String get placesTitle;

  /// No description provided for @placesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Where to next?'**
  String get placesSearchHint;

  /// No description provided for @placesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load places'**
  String get placesLoadFailed;

  /// No description provided for @placesSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get placesSeeAll;

  /// No description provided for @placesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get placesNoResults;

  /// No description provided for @placesNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try choosing another city in filters.'**
  String get placesNoResultsSubtitle;

  /// No description provided for @placesFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get placesFiltersTitle;

  /// No description provided for @placesSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get placesSortLabel;

  /// No description provided for @placesSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get placesSortRating;

  /// No description provided for @placesSortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get placesSortDuration;

  /// No description provided for @placesSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get placesSortPrice;

  /// No description provided for @placeFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get placeFilterClearAll;

  /// No description provided for @placeFilterCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get placeFilterCategoriesSection;

  /// No description provided for @placeFilterCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All Spots'**
  String get placeFilterCategoryAll;

  /// No description provided for @placeFilterCategoryParks.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get placeFilterCategoryParks;

  /// No description provided for @placeFilterCategoryMuseums.
  ///
  /// In en, this message translates to:
  /// **'Museums'**
  String get placeFilterCategoryMuseums;

  /// No description provided for @placeFilterCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get placeFilterCategoryNature;

  /// No description provided for @placeFilterCategoryArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get placeFilterCategoryArchitecture;

  /// No description provided for @placeFilterCategoryBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get placeFilterCategoryBeach;

  /// No description provided for @placeFilterCategoryTemple.
  ///
  /// In en, this message translates to:
  /// **'Temple'**
  String get placeFilterCategoryTemple;

  /// No description provided for @placeFilterCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get placeFilterCategoryEntertainment;

  /// No description provided for @placeFilterCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get placeFilterCategoryFood;

  /// No description provided for @placeFilterCategoryMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get placeFilterCategoryMarket;

  /// No description provided for @placeFilterCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get placeFilterCategoryShopping;

  /// No description provided for @placeFilterCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get placeFilterCategoryOther;

  /// No description provided for @placeFilterCategoryHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get placeFilterCategoryHistory;

  /// No description provided for @placeFilterCategoryAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get placeFilterCategoryAdventure;

  /// No description provided for @placeFilterCountrySection.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get placeFilterCountrySection;

  /// No description provided for @placeFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get placeFilterCountryAll;

  /// No description provided for @placeFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Country, code, or phone'**
  String get placeFilterCountrySearchHint;

  /// No description provided for @placeFilterCountryNoResults.
  ///
  /// In en, this message translates to:
  /// **'Country not found'**
  String get placeFilterCountryNoResults;

  /// No description provided for @placeFilterMinRatingSection.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get placeFilterMinRatingSection;

  /// No description provided for @placeFilterRatingAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get placeFilterRatingAny;

  /// No description provided for @placeFilterDurationSection.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get placeFilterDurationSection;

  /// No description provided for @placeFilterDurationShort.
  ///
  /// In en, this message translates to:
  /// **'Short < 2h'**
  String get placeFilterDurationShort;

  /// No description provided for @placeFilterDurationMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium 2–5h'**
  String get placeFilterDurationMedium;

  /// No description provided for @placeFilterDurationFullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day 5h+'**
  String get placeFilterDurationFullDay;

  /// No description provided for @placeFilterDurationMultiDay.
  ///
  /// In en, this message translates to:
  /// **'Multi-day'**
  String get placeFilterDurationMultiDay;

  /// No description provided for @placeFilterRangeSection.
  ///
  /// In en, this message translates to:
  /// **'Specific range'**
  String get placeFilterRangeSection;

  /// No description provided for @placeFilterRangeValue.
  ///
  /// In en, this message translates to:
  /// **'{min}h – {max}h'**
  String placeFilterRangeValue(int min, int max);

  /// No description provided for @placeFilterRangeMinTick.
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get placeFilterRangeMinTick;

  /// No description provided for @placeFilterRangeMaxTick.
  ///
  /// In en, this message translates to:
  /// **'12h+'**
  String get placeFilterRangeMaxTick;

  /// No description provided for @placeFilterPriceRangeSection.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get placeFilterPriceRangeSection;

  /// No description provided for @placeFilterShowSpots.
  ///
  /// In en, this message translates to:
  /// **'Show {count} spots'**
  String placeFilterShowSpots(int count);

  /// No description provided for @placeFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get placeFilterClear;

  /// No description provided for @placeMinPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get placeMinPriceLabel;

  /// No description provided for @placeMaxPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get placeMaxPriceLabel;

  /// No description provided for @placePriceValidationError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get placePriceValidationError;

  /// No description provided for @placePriceRangeValidationError.
  ///
  /// In en, this message translates to:
  /// **'Max price must be greater than min price'**
  String get placePriceRangeValidationError;

  /// No description provided for @placeHoursUnit.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get placeHoursUnit;

  /// No description provided for @placeDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get placeDaysUnit;

  /// No description provided for @placeHoursUnitShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get placeHoursUnitShort;

  /// No description provided for @placeDaysUnitShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get placeDaysUnitShort;

  /// No description provided for @placeMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get placeMinLabel;

  /// No description provided for @placeMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get placeMaxLabel;

  /// No description provided for @placeDurationValidationError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid duration'**
  String get placeDurationValidationError;

  /// No description provided for @placeDurationRangeValidationError.
  ///
  /// In en, this message translates to:
  /// **'Max duration must be greater than min'**
  String get placeDurationRangeValidationError;

  /// No description provided for @placeDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load place'**
  String get placeDetailsLoadFailed;

  /// No description provided for @placeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Place details'**
  String get placeDetailsTitle;

  /// No description provided for @placeMustVisitBadge.
  ///
  /// In en, this message translates to:
  /// **'Must visit'**
  String get placeMustVisitBadge;

  /// No description provided for @placeStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get placeStatRating;

  /// No description provided for @placeStatDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get placeStatDuration;

  /// No description provided for @placeStatPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get placeStatPrice;

  /// No description provided for @placeExperienceSection.
  ///
  /// In en, this message translates to:
  /// **'The experience'**
  String get placeExperienceSection;

  /// No description provided for @placeFeeDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get placeFeeDetailsSection;

  /// No description provided for @placeFeeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Approximate expenses'**
  String get placeFeeDetailsTitle;

  /// No description provided for @placeFeeDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'Actual tariffs may change before your visit'**
  String get placeFeeDetailsNote;

  /// No description provided for @placeExpectSection.
  ///
  /// In en, this message translates to:
  /// **'What to expect'**
  String get placeExpectSection;

  /// No description provided for @placeVisitPlanSection.
  ///
  /// In en, this message translates to:
  /// **'Plan your visit'**
  String get placeVisitPlanSection;

  /// No description provided for @placeVisitOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get placeVisitOverviewTitle;

  /// No description provided for @placeVisitCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get placeVisitCostTitle;

  /// No description provided for @placeVisitSeasonTitle.
  ///
  /// In en, this message translates to:
  /// **'When to go'**
  String get placeVisitSeasonTitle;

  /// No description provided for @placeVisitAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'How to get there'**
  String get placeVisitAccessTitle;

  /// No description provided for @placeVisitTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to plan'**
  String get placeVisitTimeTitle;

  /// No description provided for @placeVisitRecommendedItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'What to take'**
  String get placeVisitRecommendedItemsTitle;

  /// No description provided for @placeVisitPracticalNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Practical tips'**
  String get placeVisitPracticalNotesTitle;

  /// No description provided for @placeInflapTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Inflap tip'**
  String get placeInflapTipTitle;

  /// No description provided for @placeVisitDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Time needed'**
  String get placeVisitDurationLabel;

  /// No description provided for @placeVisitCarTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'By car'**
  String get placeVisitCarTimeLabel;

  /// No description provided for @placeVisitOpeningHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get placeVisitOpeningHoursLabel;

  /// No description provided for @placeVisitPriceNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Price note'**
  String get placeVisitPriceNoteLabel;

  /// No description provided for @placeVisitRoadConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get placeVisitRoadConditionLabel;

  /// No description provided for @placeVisitRouteHintLabel.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get placeVisitRouteHintLabel;

  /// No description provided for @placeVisitParkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get placeVisitParkingLabel;

  /// No description provided for @placeVisitLastSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Last segment'**
  String get placeVisitLastSegmentLabel;

  /// No description provided for @placeVisitRequires4x4.
  ///
  /// In en, this message translates to:
  /// **'4x4 needed'**
  String get placeVisitRequires4x4;

  /// No description provided for @placeVisitRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get placeVisitRequiredLabel;

  /// No description provided for @placeVisitOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get placeVisitOptionalLabel;

  /// No description provided for @placeVisitRecommendedLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get placeVisitRecommendedLabel;

  /// No description provided for @placeVisitItemWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get placeVisitItemWater;

  /// No description provided for @placeVisitItemShoes.
  ///
  /// In en, this message translates to:
  /// **'Comfortable shoes'**
  String get placeVisitItemShoes;

  /// No description provided for @placeVisitItemCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get placeVisitItemCash;

  /// No description provided for @placeVisitItemWarmClothes.
  ///
  /// In en, this message translates to:
  /// **'Warm clothes'**
  String get placeVisitItemWarmClothes;

  /// No description provided for @placeVisitItemPowerbank.
  ///
  /// In en, this message translates to:
  /// **'Power bank'**
  String get placeVisitItemPowerbank;

  /// No description provided for @placeVisitItemDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get placeVisitItemDocuments;

  /// No description provided for @placeVisitItemFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get placeVisitItemFood;

  /// No description provided for @placeVisitItemSpf.
  ///
  /// In en, this message translates to:
  /// **'SPF and hat'**
  String get placeVisitItemSpf;

  /// No description provided for @placeVisitItemRain.
  ///
  /// In en, this message translates to:
  /// **'Rain jacket'**
  String get placeVisitItemRain;

  /// No description provided for @placeVisitItemMap.
  ///
  /// In en, this message translates to:
  /// **'Offline map'**
  String get placeVisitItemMap;

  /// No description provided for @placeVisitItemRepellent.
  ///
  /// In en, this message translates to:
  /// **'Repellent'**
  String get placeVisitItemRepellent;

  /// No description provided for @placeVisitItemFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid kit'**
  String get placeVisitItemFirstAid;

  /// No description provided for @placeVisitItemOther.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get placeVisitItemOther;

  /// No description provided for @placeVisitTransportCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get placeVisitTransportCar;

  /// No description provided for @placeVisitTransportWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get placeVisitTransportWalk;

  /// No description provided for @placeVisitTransportTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get placeVisitTransportTaxi;

  /// No description provided for @placeVisitTransportBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get placeVisitTransportBus;

  /// No description provided for @placeVisitTransportCableCar.
  ///
  /// In en, this message translates to:
  /// **'Cable car'**
  String get placeVisitTransportCableCar;

  /// No description provided for @placeVisitTransportShuttle.
  ///
  /// In en, this message translates to:
  /// **'Shuttle'**
  String get placeVisitTransportShuttle;

  /// No description provided for @placeVisitTransportHorse.
  ///
  /// In en, this message translates to:
  /// **'Horse'**
  String get placeVisitTransportHorse;

  /// No description provided for @placeVisitTransportTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get placeVisitTransportTrain;

  /// No description provided for @placeVisitTransportBoat.
  ///
  /// In en, this message translates to:
  /// **'Boat'**
  String get placeVisitTransportBoat;

  /// No description provided for @placeVisitRoadPaved.
  ///
  /// In en, this message translates to:
  /// **'Paved'**
  String get placeVisitRoadPaved;

  /// No description provided for @placeVisitRoadGravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get placeVisitRoadGravel;

  /// No description provided for @placeVisitRoadMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain road'**
  String get placeVisitRoadMountain;

  /// No description provided for @placeVisitRoadMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed road'**
  String get placeVisitRoadMixed;

  /// No description provided for @placeVisitRoadOffroad.
  ///
  /// In en, this message translates to:
  /// **'Off-road'**
  String get placeVisitRoadOffroad;

  /// No description provided for @placeVisitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String placeVisitMinutes(int count);

  /// No description provided for @placeVisitHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String placeVisitHoursOnly(int hours);

  /// No description provided for @placeVisitHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String placeVisitHoursMinutes(int hours, int minutes);

  /// No description provided for @placeVisitDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String placeVisitDistanceKm(String distance);

  /// No description provided for @placeVisitDurationFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get placeVisitDurationFlexible;

  /// No description provided for @placeVisitTicketsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get placeVisitTicketsLabel;

  /// No description provided for @placeVisitFreeEntry.
  ///
  /// In en, this message translates to:
  /// **'Free or varies'**
  String get placeVisitFreeEntry;

  /// No description provided for @placeVisitBookingRecommended.
  ///
  /// In en, this message translates to:
  /// **'book ahead'**
  String get placeVisitBookingRecommended;

  /// No description provided for @placeVisitBestTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get placeVisitBestTimeLabel;

  /// No description provided for @placeVisitBestTimeEarlyMorning.
  ///
  /// In en, this message translates to:
  /// **'Early morning'**
  String get placeVisitBestTimeEarlyMorning;

  /// No description provided for @placeVisitBestTimeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get placeVisitBestTimeMorning;

  /// No description provided for @placeVisitBestTimeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get placeVisitBestTimeAfternoon;

  /// No description provided for @placeVisitBestTimeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get placeVisitBestTimeSunset;

  /// No description provided for @placeVisitBestTimeAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get placeVisitBestTimeAnytime;

  /// No description provided for @placeVisitGoodForLabel.
  ///
  /// In en, this message translates to:
  /// **'Good for'**
  String get placeVisitGoodForLabel;

  /// No description provided for @placeVisitAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get placeVisitAccessLabel;

  /// No description provided for @placeVisitAccessGood.
  ///
  /// In en, this message translates to:
  /// **'Easy access'**
  String get placeVisitAccessGood;

  /// No description provided for @placeVisitAccessLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited access'**
  String get placeVisitAccessLimited;

  /// No description provided for @placeVisitAccessUnknown.
  ///
  /// In en, this message translates to:
  /// **'Check locally'**
  String get placeVisitAccessUnknown;

  /// No description provided for @placeVisitSafetyLabel.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get placeVisitSafetyLabel;

  /// No description provided for @placeVisitSafetyCheckWeather.
  ///
  /// In en, this message translates to:
  /// **'Check weather'**
  String get placeVisitSafetyCheckWeather;

  /// No description provided for @placeVisitSafetyBringWater.
  ///
  /// In en, this message translates to:
  /// **'Bring water'**
  String get placeVisitSafetyBringWater;

  /// No description provided for @placeVisitSafetyCheckHours.
  ///
  /// In en, this message translates to:
  /// **'Check hours'**
  String get placeVisitSafetyCheckHours;

  /// No description provided for @placeVisitAudienceCouples.
  ///
  /// In en, this message translates to:
  /// **'Couples'**
  String get placeVisitAudienceCouples;

  /// No description provided for @placeVisitAudienceWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get placeVisitAudienceWellness;

  /// No description provided for @placeVisitTipNature.
  ///
  /// In en, this message translates to:
  /// **'Plan transport and weather before you go; guided routes are usually safer and more predictable.'**
  String get placeVisitTipNature;

  /// No description provided for @placeVisitTipCulture.
  ///
  /// In en, this message translates to:
  /// **'Come earlier in the day for calmer photos and leave time for nearby cultural stops.'**
  String get placeVisitTipCulture;

  /// No description provided for @placeVisitTipDefault.
  ///
  /// In en, this message translates to:
  /// **'Check current hours and combine this stop with nearby activities to avoid losing time in transit.'**
  String get placeVisitTipDefault;

  /// No description provided for @placeVisitPracticalGeneral.
  ///
  /// In en, this message translates to:
  /// **'Practical tip'**
  String get placeVisitPracticalGeneral;

  /// No description provided for @placeVisitPracticalConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get placeVisitPracticalConnection;

  /// No description provided for @placeVisitPracticalToilet.
  ///
  /// In en, this message translates to:
  /// **'Toilets'**
  String get placeVisitPracticalToilet;

  /// No description provided for @placeVisitPracticalCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get placeVisitPracticalCafe;

  /// No description provided for @placeVisitPracticalSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get placeVisitPracticalSafety;

  /// No description provided for @placeVisitPracticalKids.
  ///
  /// In en, this message translates to:
  /// **'With kids'**
  String get placeVisitPracticalKids;

  /// No description provided for @placeVisitPracticalWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get placeVisitPracticalWeather;

  /// No description provided for @placeReviewsSection.
  ///
  /// In en, this message translates to:
  /// **'Tourist reviews'**
  String get placeReviewsSection;

  /// No description provided for @placeSeeAllReviews.
  ///
  /// In en, this message translates to:
  /// **'See all ({count})'**
  String placeSeeAllReviews(int count);

  /// No description provided for @placeNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first!'**
  String get placeNoReviews;

  /// No description provided for @placeAddReview.
  ///
  /// In en, this message translates to:
  /// **'Add review'**
  String get placeAddReview;

  /// No description provided for @placeReviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your visit'**
  String get placeReviewSheetTitle;

  /// No description provided for @placeReviewRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get placeReviewRatingLabel;

  /// No description provided for @placeReviewCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get placeReviewCommentLabel;

  /// No description provided for @placeReviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'What stood out, what would you recommend, and what should others know?'**
  String get placeReviewCommentHint;

  /// No description provided for @placeReviewAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get placeReviewAddPhoto;

  /// No description provided for @placeReviewAddVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get placeReviewAddVideo;

  /// No description provided for @placeReviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Publish review'**
  String get placeReviewSubmit;

  /// No description provided for @placeReviewSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get placeReviewSubmitting;

  /// No description provided for @placeReviewMediaLimit.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to {count} files'**
  String placeReviewMediaLimit(int count);

  /// No description provided for @placeReviewPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not attach this file'**
  String get placeReviewPickFailed;

  /// No description provided for @placeReviewMediaTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large'**
  String get placeReviewMediaTooLarge;

  /// No description provided for @placeReviewUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format'**
  String get placeReviewUnsupportedFormat;

  /// No description provided for @placeReviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish the review'**
  String get placeReviewSubmitFailed;

  /// No description provided for @placeReviewSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Review published'**
  String get placeReviewSubmitSuccess;

  /// No description provided for @placeReviewCommentRequired.
  ///
  /// In en, this message translates to:
  /// **'Write a short comment'**
  String get placeReviewCommentRequired;

  /// No description provided for @placeReviewRemoveMedia.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get placeReviewRemoveMedia;

  /// No description provided for @placeReviewVideoPreview.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get placeReviewVideoPreview;

  /// No description provided for @placeFindExcursions.
  ///
  /// In en, this message translates to:
  /// **'Find excursions'**
  String get placeFindExcursions;

  /// No description provided for @placeMapLink.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get placeMapLink;

  /// No description provided for @placeVerifiedNomad.
  ///
  /// In en, this message translates to:
  /// **'Verified nomad'**
  String get placeVerifiedNomad;

  /// No description provided for @placeReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tourist reviews'**
  String get placeReviewsTitle;

  /// No description provided for @placeTravelerFallback.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get placeTravelerFallback;

  /// No description provided for @profileGuideReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Best excursion reviews'**
  String get profileGuideReviewsTitle;

  /// No description provided for @profileGuideReviewsLatestTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest excursion reviews'**
  String get profileGuideReviewsLatestTitle;

  /// No description provided for @profileDirectGuideReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide rating'**
  String get profileDirectGuideReviewsTitle;

  /// No description provided for @profileActivityOrganizerReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity organizer rating'**
  String get profileActivityOrganizerReviewsTitle;

  /// No description provided for @profileActivityReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity reviews'**
  String get profileActivityReviewsTitle;

  /// No description provided for @profileGuideReviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get profileGuideReviewsEmptyTitle;

  /// No description provided for @profileGuideReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Reviews will appear here after travelers rate completed excursions.'**
  String get profileGuideReviewsEmpty;

  /// No description provided for @profileDirectGuideReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Direct guide reviews will appear here after travelers rate the guide.'**
  String get profileDirectGuideReviewsEmpty;

  /// No description provided for @profileActivityOrganizerReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Organizer reviews will appear here after participants rate completed activities.'**
  String get profileActivityOrganizerReviewsEmpty;

  /// No description provided for @profileActivityReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Activity reviews will appear here after participants rate completed activities.'**
  String get profileActivityReviewsEmpty;

  /// No description provided for @profileGuideReviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load reviews'**
  String get profileGuideReviewsLoadFailed;

  /// No description provided for @profileGuideReviewsLoadFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh or open the profile again.'**
  String get profileGuideReviewsLoadFailedHint;

  /// No description provided for @placePriceVaries.
  ///
  /// In en, this message translates to:
  /// **'price to confirm'**
  String get placePriceVaries;

  /// No description provided for @placePriceVariesShort.
  ///
  /// In en, this message translates to:
  /// **'to confirm'**
  String get placePriceVariesShort;

  /// No description provided for @placeFreeEntry.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get placeFreeEntry;

  /// No description provided for @placePriceFrom.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String placePriceFrom(Object price);

  /// No description provided for @placeFeeApproxAmount.
  ///
  /// In en, this message translates to:
  /// **'~{amount}'**
  String placeFeeApproxAmount(Object amount);

  /// No description provided for @placeFeePerUnit.
  ///
  /// In en, this message translates to:
  /// **'{amount} per {unit}'**
  String placeFeePerUnit(Object amount, Object unit);

  /// No description provided for @placeFeeUnitPerson.
  ///
  /// In en, this message translates to:
  /// **'person'**
  String get placeFeeUnitPerson;

  /// No description provided for @placeFeeUnitCar.
  ///
  /// In en, this message translates to:
  /// **'car'**
  String get placeFeeUnitCar;

  /// No description provided for @placeFeeUnitMotorcycle.
  ///
  /// In en, this message translates to:
  /// **'motorcycle'**
  String get placeFeeUnitMotorcycle;

  /// No description provided for @placeFeeUnitTicket.
  ///
  /// In en, this message translates to:
  /// **'ticket'**
  String get placeFeeUnitTicket;

  /// No description provided for @placeFeeUnitGroup.
  ///
  /// In en, this message translates to:
  /// **'group'**
  String get placeFeeUnitGroup;

  /// No description provided for @placeFeeUnitItem.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get placeFeeUnitItem;

  /// No description provided for @placeDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String placeDurationHours(int hours);

  /// No description provided for @placeDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String placeDurationDays(int days);

  /// No description provided for @placeBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get placeBackTooltip;

  /// No description provided for @placeNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get placeNotificationsTooltip;

  /// No description provided for @placeBookmarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get placeBookmarkTooltip;

  /// No description provided for @placeTagFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Family friendly'**
  String get placeTagFamilyLabel;

  /// No description provided for @placeTagFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suitable for all ages'**
  String get placeTagFamilySubtitle;

  /// No description provided for @placeTagSunsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Best at sunset'**
  String get placeTagSunsetLabel;

  /// No description provided for @placeTagSunsetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stunning twilight views'**
  String get placeTagSunsetSubtitle;

  /// No description provided for @placeTagAccessibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get placeTagAccessibilityLabel;

  /// No description provided for @placeTagAccessibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair friendly'**
  String get placeTagAccessibilitySubtitle;

  /// No description provided for @placeTagDiningLabel.
  ///
  /// In en, this message translates to:
  /// **'Fine dining'**
  String get placeTagDiningLabel;

  /// No description provided for @placeTagDiningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gourmet restaurants'**
  String get placeTagDiningSubtitle;

  /// No description provided for @placeTagOutdoorLabel.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get placeTagOutdoorLabel;

  /// No description provided for @placeTagOutdoorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nature and fresh air'**
  String get placeTagOutdoorSubtitle;

  /// No description provided for @placeTagPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo spot'**
  String get placeTagPhotoLabel;

  /// No description provided for @placeTagPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Great for memorable shots'**
  String get placeTagPhotoSubtitle;

  /// No description provided for @placeTagHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Historic'**
  String get placeTagHistoryLabel;

  /// No description provided for @placeTagHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rich cultural heritage'**
  String get placeTagHistorySubtitle;

  /// No description provided for @placeTagAdventureLabel.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get placeTagAdventureLabel;

  /// No description provided for @placeTagAdventureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active experiences'**
  String get placeTagAdventureSubtitle;

  /// No description provided for @placeTagUniqueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unique experience'**
  String get placeTagUniqueSubtitle;

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

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

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

  /// No description provided for @excursionsDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Excursions'**
  String get excursionsDiscoverTitle;

  /// No description provided for @excursionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Excursions and experiences'**
  String get excursionsSearchHint;

  /// No description provided for @excursionsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get excursionsSortLabel;

  /// No description provided for @excursionsSortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get excursionsSortPopular;

  /// No description provided for @excursionsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get excursionsSortNewest;

  /// No description provided for @excursionsSortAffordable.
  ///
  /// In en, this message translates to:
  /// **'Affordable'**
  String get excursionsSortAffordable;

  /// No description provided for @excursionsSortCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get excursionsSortCreatedAt;

  /// No description provided for @excursionsSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get excursionsSortRating;

  /// No description provided for @excursionsSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get excursionsSortPrice;

  /// No description provided for @excursionsSortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get excursionsSortDuration;

  /// No description provided for @excursionsFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get excursionsFiltersTitle;

  /// No description provided for @excursionsFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get excursionsFiltersClear;

  /// No description provided for @excursionsFiltersShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show {count, plural, =0{0 excursions} =1{1 excursion} other{{count} excursions}}'**
  String excursionsFiltersShowResults(num count);

  /// No description provided for @excursionsFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get excursionsFilterCountry;

  /// No description provided for @excursionsFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get excursionsFilterCountryAll;

  /// No description provided for @excursionsFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Country, code, or phone'**
  String get excursionsFilterCountrySearchHint;

  /// No description provided for @excursionsFilterCountryNoResults.
  ///
  /// In en, this message translates to:
  /// **'Country not found'**
  String get excursionsFilterCountryNoResults;

  /// No description provided for @excursionsFilterCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get excursionsFilterCategories;

  /// No description provided for @excursionsFilterPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get excursionsFilterPriceRange;

  /// No description provided for @excursionsFilterPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get excursionsFilterPriceFrom;

  /// No description provided for @excursionsFilterPriceTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get excursionsFilterPriceTo;

  /// No description provided for @excursionsFilterBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get excursionsFilterBudget;

  /// No description provided for @excursionsFilterPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get excursionsFilterPremium;

  /// No description provided for @excursionsFilterDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get excursionsFilterDuration;

  /// No description provided for @excursionsFilterShortDuration.
  ///
  /// In en, this message translates to:
  /// **'Short (< 3h)'**
  String get excursionsFilterShortDuration;

  /// No description provided for @excursionsFilterHalfDayDuration.
  ///
  /// In en, this message translates to:
  /// **'Half Day (3–6h)'**
  String get excursionsFilterHalfDayDuration;

  /// No description provided for @excursionsFilterFullDayDuration.
  ///
  /// In en, this message translates to:
  /// **'Full Day (6h+)'**
  String get excursionsFilterFullDayDuration;

  /// No description provided for @excursionsFilterMultiDayDuration.
  ///
  /// In en, this message translates to:
  /// **'Multi-day'**
  String get excursionsFilterMultiDayDuration;

  /// No description provided for @excursionsFilterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get excursionsFilterLanguage;

  /// No description provided for @excursionsFilterLanguageAll.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get excursionsFilterLanguageAll;

  /// No description provided for @excursionsFilterLanguageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Language or code'**
  String get excursionsFilterLanguageSearchHint;

  /// No description provided for @excursionsFilterLanguageNoResults.
  ///
  /// In en, this message translates to:
  /// **'Language not found'**
  String get excursionsFilterLanguageNoResults;

  /// No description provided for @excursionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load excursions'**
  String get excursionsLoadFailed;

  /// No description provided for @excursionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No excursions yet'**
  String get excursionsEmptyTitle;

  /// No description provided for @excursionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified guide routes will appear here. Try choosing another city in filters.'**
  String get excursionsEmptySubtitle;

  /// No description provided for @excursionsEmptySearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another city, category, or excursion name.'**
  String get excursionsEmptySearchSubtitle;

  /// No description provided for @excursionsNoPlaceExcursionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No excursions for this place yet'**
  String get excursionsNoPlaceExcursionsTitle;

  /// No description provided for @excursionsNoPlaceExcursionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showing other available excursions. When guides add a route for this place, it will appear here.'**
  String get excursionsNoPlaceExcursionsSubtitle;

  /// No description provided for @guidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Guides'**
  String get guidesTitle;

  /// No description provided for @guidesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guidesSearchHint;

  /// No description provided for @guidesSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get guidesSortLabel;

  /// No description provided for @guidesSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get guidesSortRating;

  /// No description provided for @guidesSortExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get guidesSortExperience;

  /// No description provided for @guidesViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get guidesViewProfile;

  /// No description provided for @guidesFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get guidesFiltersTitle;

  /// No description provided for @guidesFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get guidesFiltersClear;

  /// No description provided for @guidesClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get guidesClearSearch;

  /// No description provided for @guidesFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get guidesFilterCountry;

  /// No description provided for @guidesFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get guidesFilterCountryAll;

  /// No description provided for @guidesFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Country, code, or phone'**
  String get guidesFilterCountrySearchHint;

  /// No description provided for @guidesFilterCountryNoResults.
  ///
  /// In en, this message translates to:
  /// **'Country not found'**
  String get guidesFilterCountryNoResults;

  /// No description provided for @guidesFilterExpertise.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get guidesFilterExpertise;

  /// No description provided for @guidesFilterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get guidesFilterLanguage;

  /// No description provided for @guidesFilterLanguageAll.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get guidesFilterLanguageAll;

  /// No description provided for @guidesFilterLanguageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Language or code'**
  String get guidesFilterLanguageSearchHint;

  /// No description provided for @guidesFilterLanguageNoResults.
  ///
  /// In en, this message translates to:
  /// **'Language not found'**
  String get guidesFilterLanguageNoResults;

  /// No description provided for @guidesFilterRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get guidesFilterRating;

  /// No description provided for @guidesFilterExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get guidesFilterExperience;

  /// No description provided for @guidesFilterRatingAtLeast.
  ///
  /// In en, this message translates to:
  /// **'{value}+ stars'**
  String guidesFilterRatingAtLeast(Object value);

  /// No description provided for @guidesFiltersShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show {count, plural, =0{0 guides} =1{1 guide} other{{count} guides}}'**
  String guidesFiltersShowResults(num count);

  /// No description provided for @guidesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load guides'**
  String get guidesLoadFailed;

  /// No description provided for @guidesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No guides yet'**
  String get guidesEmptyTitle;

  /// No description provided for @guidesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified local experts will appear here. Try choosing another city in filters.'**
  String get guidesEmptySubtitle;

  /// No description provided for @guidesNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No guides found'**
  String get guidesNoResultsTitle;

  /// No description provided for @guidesNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another city, name, expertise, language, or filter.'**
  String get guidesNoResultsSubtitle;

  /// No description provided for @guidesRatingNew.
  ///
  /// In en, this message translates to:
  /// **'New guide'**
  String get guidesRatingNew;

  /// No description provided for @guidesReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String guidesReviewsCount(num count);

  /// No description provided for @guidesSpecialtyMountainGuide.
  ///
  /// In en, this message translates to:
  /// **'Mountain Guide'**
  String get guidesSpecialtyMountainGuide;

  /// No description provided for @guidesSpecialtyCityHistorian.
  ///
  /// In en, this message translates to:
  /// **'City Historian'**
  String get guidesSpecialtyCityHistorian;

  /// No description provided for @guidesSpecialtyCulinaryExpert.
  ///
  /// In en, this message translates to:
  /// **'Culinary Expert'**
  String get guidesSpecialtyCulinaryExpert;

  /// No description provided for @guidesSpecialtyNaturePhotographer.
  ///
  /// In en, this message translates to:
  /// **'Nature Photographer'**
  String get guidesSpecialtyNaturePhotographer;

  /// No description provided for @guidesRoleLocalExpert.
  ///
  /// In en, this message translates to:
  /// **'Local Expert'**
  String get guidesRoleLocalExpert;

  /// No description provided for @guidesFilterPrivateExcursions.
  ///
  /// In en, this message translates to:
  /// **'Private excursions'**
  String get guidesFilterPrivateExcursions;

  /// No description provided for @guidesFilterActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get guidesFilterActivities;

  /// No description provided for @guidesFilterExcursions.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get guidesFilterExcursions;

  /// No description provided for @guidesExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String guidesExperienceYears(num count);

  /// No description provided for @excursionsCreateFab.
  ///
  /// In en, this message translates to:
  /// **'Create excursion'**
  String get excursionsCreateFab;

  /// No description provided for @excursionsFreePrice.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get excursionsFreePrice;

  /// No description provided for @excursionsPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String excursionsPriceFrom(Object price);

  /// No description provided for @excursionsOffersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No guides yet} =1{1 guide} other{{count} guides}}'**
  String excursionsOffersCount(num count);

  /// No description provided for @excursionsDurationHourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get excursionsDurationHourShort;

  /// No description provided for @excursionsDurationMinuteShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get excursionsDurationMinuteShort;

  /// No description provided for @excursionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion Details'**
  String get excursionDetailsTitle;

  /// No description provided for @excursionDetailsPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get excursionDetailsPrice;

  /// No description provided for @excursionDetailsPerPerson.
  ///
  /// In en, this message translates to:
  /// **'/pp'**
  String get excursionDetailsPerPerson;

  /// No description provided for @excursionDetailsIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get excursionDetailsIntensity;

  /// No description provided for @excursionDetailsIntensityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get excursionDetailsIntensityModerate;

  /// No description provided for @excursionDetailsGroupSize.
  ///
  /// In en, this message translates to:
  /// **'Group Size'**
  String get excursionDetailsGroupSize;

  /// No description provided for @excursionDetailsGroupSizeUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {count}'**
  String excursionDetailsGroupSizeUpTo(Object count);

  /// No description provided for @excursionDetailsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get excursionDetailsLanguage;

  /// No description provided for @excursionLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get excursionLanguageEnglish;

  /// No description provided for @excursionLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get excursionLanguageRussian;

  /// No description provided for @excursionLanguageKazakh.
  ///
  /// In en, this message translates to:
  /// **'Kazakh'**
  String get excursionLanguageKazakh;

  /// No description provided for @excursionLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get excursionLanguageFrench;

  /// No description provided for @excursionLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get excursionLanguageJapanese;

  /// No description provided for @excursionLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get excursionLanguageGerman;

  /// No description provided for @excursionLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get excursionLanguageSpanish;

  /// No description provided for @excursionLanguageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get excursionLanguageTurkish;

  /// No description provided for @excursionDetailsExperience.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get excursionDetailsExperience;

  /// No description provided for @excursionDetailsWhatToExpect.
  ///
  /// In en, this message translates to:
  /// **'What to expect'**
  String get excursionDetailsWhatToExpect;

  /// No description provided for @excursionDetailsSelectedOfferIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included with selected guide'**
  String get excursionDetailsSelectedOfferIncluded;

  /// No description provided for @excursionDetailsLeadGuide.
  ///
  /// In en, this message translates to:
  /// **'Your Lead Guide'**
  String get excursionDetailsLeadGuide;

  /// No description provided for @excursionDetailsGuideName.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get excursionDetailsGuideName;

  /// No description provided for @excursionDetailsGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified local expert'**
  String get excursionDetailsGuideSubtitle;

  /// No description provided for @excursionDetailsGuideQuote.
  ///
  /// In en, this message translates to:
  /// **'Every route is more memorable with local context, thoughtful timing, and a guide who knows when to slow down.'**
  String get excursionDetailsGuideQuote;

  /// No description provided for @excursionDetailsMessageGuide.
  ///
  /// In en, this message translates to:
  /// **'Message Guide'**
  String get excursionDetailsMessageGuide;

  /// No description provided for @excursionDetailsOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Available guides'**
  String get excursionDetailsOffersTitle;

  /// No description provided for @excursionDetailsOffersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No guides available yet'**
  String get excursionDetailsOffersEmpty;

  /// No description provided for @excursionDetailsOfferSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get excursionDetailsOfferSelected;

  /// No description provided for @excursionDetailsOfferCurrentUser.
  ///
  /// In en, this message translates to:
  /// **'This is you'**
  String get excursionDetailsOfferCurrentUser;

  /// No description provided for @excursionDetailsOffersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Guides or offers'**
  String get excursionDetailsOffersSearchHint;

  /// No description provided for @excursionDetailsOffersLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Show more guides'**
  String get excursionDetailsOffersLoadMore;

  /// No description provided for @excursionDetailsOffersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load guides'**
  String get excursionDetailsOffersLoadFailed;

  /// No description provided for @excursionDetailsOffersSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get excursionDetailsOffersSortRating;

  /// No description provided for @excursionDetailsOffersSortExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get excursionDetailsOffersSortExperience;

  /// No description provided for @excursionDetailsOffersSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get excursionDetailsOffersSortPrice;

  /// No description provided for @excursionDetailsOffersFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide filters'**
  String get excursionDetailsOffersFiltersTitle;

  /// No description provided for @excursionDetailsOffersMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get excursionDetailsOffersMaxPrice;

  /// No description provided for @excursionDetailsOffersMaxPriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50000'**
  String get excursionDetailsOffersMaxPriceHint;

  /// No description provided for @excursionDetailsOffersAvailableDate.
  ///
  /// In en, this message translates to:
  /// **'Available date'**
  String get excursionDetailsOffersAvailableDate;

  /// No description provided for @excursionDetailsOffersAvailableDateHint.
  ///
  /// In en, this message translates to:
  /// **'dd.mm.yyyy'**
  String get excursionDetailsOffersAvailableDateHint;

  /// No description provided for @excursionDetailsOffersAvailableDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the date as dd.mm.yyyy'**
  String get excursionDetailsOffersAvailableDateInvalid;

  /// No description provided for @excursionDetailsOffersMinGroup.
  ///
  /// In en, this message translates to:
  /// **'Minimum group size'**
  String get excursionDetailsOffersMinGroup;

  /// No description provided for @excursionDetailsOffersMinGroupHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4'**
  String get excursionDetailsOffersMinGroupHint;

  /// No description provided for @excursionDetailsOffersLanguageAny.
  ///
  /// In en, this message translates to:
  /// **'Any language'**
  String get excursionDetailsOffersLanguageAny;

  /// No description provided for @excursionDetailsOffersLanguageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Language or code'**
  String get excursionDetailsOffersLanguageSearchHint;

  /// No description provided for @excursionDetailsOffersLanguageNoResults.
  ///
  /// In en, this message translates to:
  /// **'Language not found'**
  String get excursionDetailsOffersLanguageNoResults;

  /// No description provided for @excursionDetailsOffersApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get excursionDetailsOffersApplyFilters;

  /// No description provided for @excursionDetailsMapPreview.
  ///
  /// In en, this message translates to:
  /// **'Route meeting point'**
  String get excursionDetailsMapPreview;

  /// No description provided for @excursionDetailsItinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get excursionDetailsItinerary;

  /// No description provided for @excursionDetailsMeetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get excursionDetailsMeetingPoint;

  /// No description provided for @excursionDetailsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get excursionDetailsTotal;

  /// No description provided for @excursionDetailsBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get excursionDetailsBook;

  /// No description provided for @excursionDetailsBookingSeatCheckNote.
  ///
  /// In en, this message translates to:
  /// **'Exact seats for your group are checked on the booking screen.'**
  String get excursionDetailsBookingSeatCheckNote;

  /// No description provided for @excursionDetailsCheckingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Checking available times...'**
  String get excursionDetailsCheckingSchedule;

  /// No description provided for @excursionDetailsNoAvailableSlots.
  ///
  /// In en, this message translates to:
  /// **'This guide has no available time slots for this excursion yet.'**
  String get excursionDetailsNoAvailableSlots;

  /// No description provided for @excursionDetailsEditOffer.
  ///
  /// In en, this message translates to:
  /// **'Edit offer'**
  String get excursionDetailsEditOffer;

  /// No description provided for @excursionDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load excursion'**
  String get excursionDetailsLoadFailed;

  /// No description provided for @excursionDetailsBookingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Excursion booking will be available soon.'**
  String get excursionDetailsBookingComingSoon;

  /// No description provided for @excursionDetailsGuideChatComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Guide chat will be available soon.'**
  String get excursionDetailsGuideChatComingSoon;

  /// No description provided for @excursionBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Excursion'**
  String get excursionBookingTitle;

  /// No description provided for @excursionBookingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get excursionBookingSchedule;

  /// No description provided for @excursionBookingChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get excursionBookingChange;

  /// No description provided for @excursionBookingDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get excursionBookingDate;

  /// No description provided for @excursionBookingTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Time Slot'**
  String get excursionBookingTimeSlot;

  /// No description provided for @excursionBookingTravelers.
  ///
  /// In en, this message translates to:
  /// **'Travelers'**
  String get excursionBookingTravelers;

  /// No description provided for @excursionBookingAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get excursionBookingAdults;

  /// No description provided for @excursionBookingChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get excursionBookingChildren;

  /// No description provided for @excursionBookingSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get excursionBookingSummary;

  /// No description provided for @excursionBookingAdultSummary.
  ///
  /// In en, this message translates to:
  /// **'Adult ({count} x {price})'**
  String excursionBookingAdultSummary(Object count, Object price);

  /// No description provided for @excursionBookingChildrenSummary.
  ///
  /// In en, this message translates to:
  /// **'Children ({count} x {price})'**
  String excursionBookingChildrenSummary(Object count, Object price);

  /// No description provided for @excursionBookingServiceFeeSummary.
  ///
  /// In en, this message translates to:
  /// **'Service fee (5%)'**
  String get excursionBookingServiceFeeSummary;

  /// No description provided for @excursionBookingTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get excursionBookingTotalPrice;

  /// No description provided for @excursionBookingConfirmReservation.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get excursionBookingConfirmReservation;

  /// No description provided for @excursionBookingPaymentPendingNote.
  ///
  /// In en, this message translates to:
  /// **'No payment is charged now. Online payment will appear when it is connected. Total: {amount}'**
  String excursionBookingPaymentPendingNote(Object amount);

  /// No description provided for @excursionBookingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Booking is confirmed. Online payment will be connected soon.'**
  String get excursionBookingSubmitted;

  /// No description provided for @excursionBookingChecklistAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip preparation is ready'**
  String get excursionBookingChecklistAddedTitle;

  /// No description provided for @excursionBookingChecklistAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Inflap prepared a checklist for this booking: documents, weather, baggage rules, and activity essentials.'**
  String get excursionBookingChecklistAddedMessage;

  /// No description provided for @excursionBookingOpenChecklist.
  ///
  /// In en, this message translates to:
  /// **'Open checklist'**
  String get excursionBookingOpenChecklist;

  /// No description provided for @excursionBookingAlreadyBookedTitle.
  ///
  /// In en, this message translates to:
  /// **'You already booked this time'**
  String get excursionBookingAlreadyBookedTitle;

  /// No description provided for @excursionBookingAlreadyBookedMessage.
  ///
  /// In en, this message translates to:
  /// **'You can change the number of guests in My excursions.'**
  String get excursionBookingAlreadyBookedMessage;

  /// No description provided for @excursionBookingOpenMyExcursions.
  ///
  /// In en, this message translates to:
  /// **'Open My excursions'**
  String get excursionBookingOpenMyExcursions;

  /// No description provided for @excursionBookingLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load excursion booking'**
  String get excursionBookingLoadFailed;

  /// No description provided for @excursionBookingPerPerson.
  ///
  /// In en, this message translates to:
  /// **'/ person'**
  String get excursionBookingPerPerson;

  /// No description provided for @excursionBookingSelectSlot.
  ///
  /// In en, this message translates to:
  /// **'Select an available time'**
  String get excursionBookingSelectSlot;

  /// No description provided for @excursionBookingSelectedSlotUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected time is no longer available for {count} guests. Choose another time.'**
  String excursionBookingSelectedSlotUnavailable(Object count);

  /// No description provided for @excursionBookingScheduleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load available times'**
  String get excursionBookingScheduleLoadFailed;

  /// No description provided for @excursionBookingNoSlots.
  ///
  /// In en, this message translates to:
  /// **'The guide has not added available times for this offer yet.'**
  String get excursionBookingNoSlots;

  /// No description provided for @excursionBookingSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} seats left'**
  String excursionBookingSeatsLeft(Object count);

  /// No description provided for @excursionDetailsNoDescription.
  ///
  /// In en, this message translates to:
  /// **'Your guide will share the detailed description soon.'**
  String get excursionDetailsNoDescription;

  /// No description provided for @excursionDetailsRouteStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String excursionDetailsRouteStopsCount(Object count);

  /// No description provided for @excursionDetailsTravelFromPrevious.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min from previous stop'**
  String excursionDetailsTravelFromPrevious(Object minutes);

  /// No description provided for @createExcursionTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Excursion'**
  String get createExcursionTitle;

  /// No description provided for @createExcursionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Offer'**
  String get createExcursionEditTitle;

  /// No description provided for @createExcursionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get createExcursionSubmit;

  /// No description provided for @createExcursionSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get createExcursionSaveDraft;

  /// No description provided for @createExcursionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get createExcursionSaveChanges;

  /// No description provided for @createExcursionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Excursion sent for review'**
  String get createExcursionSuccess;

  /// No description provided for @createExcursionDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get createExcursionDraftSaved;

  /// No description provided for @createExcursionUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer updated successfully'**
  String get createExcursionUpdateSuccess;

  /// No description provided for @createExcursionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create excursion'**
  String get createExcursionFailed;

  /// No description provided for @createExcursionUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update offer'**
  String get createExcursionUpdateFailed;

  /// No description provided for @createExcursionCoverSection.
  ///
  /// In en, this message translates to:
  /// **'Excursion Cover'**
  String get createExcursionCoverSection;

  /// No description provided for @createExcursionCoverUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Excursion Image'**
  String get createExcursionCoverUploadTitle;

  /// No description provided for @createExcursionCoverChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Change Excursion Image'**
  String get createExcursionCoverChangeAction;

  /// No description provided for @createExcursionCoverUploadHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or WEBP. If you selected a place, its photo will be used unless you upload your own.'**
  String get createExcursionCoverUploadHint;

  /// No description provided for @createExcursionSelectedLandmark.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get createExcursionSelectedLandmark;

  /// No description provided for @createExcursionLandmarkNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get createExcursionLandmarkNameLabel;

  /// No description provided for @createExcursionLandmarkNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Medeu'**
  String get createExcursionLandmarkNameHint;

  /// No description provided for @createExcursionLandmarkValidation.
  ///
  /// In en, this message translates to:
  /// **'Choose a place'**
  String get createExcursionLandmarkValidation;

  /// No description provided for @createExcursionCountryValidation.
  ///
  /// In en, this message translates to:
  /// **'Select a country first'**
  String get createExcursionCountryValidation;

  /// No description provided for @createExcursionSelectCountryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a country first'**
  String get createExcursionSelectCountryFirst;

  /// No description provided for @createExcursionManualLocationHint.
  ///
  /// In en, this message translates to:
  /// **'You can enter a custom location or choose a place from this country.'**
  String get createExcursionManualLocationHint;

  /// No description provided for @createExcursionLocationLockedByPlace.
  ///
  /// In en, this message translates to:
  /// **'This location comes from the places catalog. Change the place to edit it.'**
  String get createExcursionLocationLockedByPlace;

  /// No description provided for @createExcursionPlaceCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Places catalog for the selected country'**
  String get createExcursionPlaceCatalogHint;

  /// No description provided for @createExcursionPlaceCatalogSource.
  ///
  /// In en, this message translates to:
  /// **'From the places catalog'**
  String get createExcursionPlaceCatalogSource;

  /// No description provided for @createExcursionSinglePlaceMode.
  ///
  /// In en, this message translates to:
  /// **'Single place'**
  String get createExcursionSinglePlaceMode;

  /// No description provided for @createExcursionCombinedRouteMode.
  ///
  /// In en, this message translates to:
  /// **'Combined route'**
  String get createExcursionCombinedRouteMode;

  /// No description provided for @createExcursionCombinedRouteMinStopsValidation.
  ///
  /// In en, this message translates to:
  /// **'Add at least {count} place stops'**
  String createExcursionCombinedRouteMinStopsValidation(Object count);

  /// No description provided for @createExcursionCombinedRouteMaxStopsValidation.
  ///
  /// In en, this message translates to:
  /// **'Add no more than {count} place stops'**
  String createExcursionCombinedRouteMaxStopsValidation(Object count);

  /// No description provided for @createExcursionDuplicateRouteStopValidation.
  ///
  /// In en, this message translates to:
  /// **'This place is already in the route.'**
  String get createExcursionDuplicateRouteStopValidation;

  /// No description provided for @excursionSelectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select place'**
  String get excursionSelectLocationTitle;

  /// No description provided for @excursionSelectLocationCountrySection.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get excursionSelectLocationCountrySection;

  /// No description provided for @excursionSelectLocationCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get excursionSelectLocationCountrySearchHint;

  /// No description provided for @excursionCountryKazakhstan.
  ///
  /// In en, this message translates to:
  /// **'Kazakhstan'**
  String get excursionCountryKazakhstan;

  /// No description provided for @excursionCountryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get excursionCountryFrance;

  /// No description provided for @excursionCountryJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get excursionCountryJapan;

  /// No description provided for @excursionCountryItaly.
  ///
  /// In en, this message translates to:
  /// **'Italy'**
  String get excursionCountryItaly;

  /// No description provided for @excursionSelectLocationPlaceSection.
  ///
  /// In en, this message translates to:
  /// **'Select place'**
  String get excursionSelectLocationPlaceSection;

  /// No description provided for @excursionSelectLocationPlaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get excursionSelectLocationPlaceSearchHint;

  /// No description provided for @excursionSelectLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get excursionSelectLocationSelected;

  /// No description provided for @excursionSelectLocationPageCaption.
  ///
  /// In en, this message translates to:
  /// **'PAGE {current} OF {total}'**
  String excursionSelectLocationPageCaption(Object current, Object total);

  /// No description provided for @createExcursionCategorization.
  ///
  /// In en, this message translates to:
  /// **'Travel Categorization'**
  String get createExcursionCategorization;

  /// No description provided for @createExcursionCategoryAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get createExcursionCategoryAdventure;

  /// No description provided for @createExcursionCategoryCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get createExcursionCategoryCultural;

  /// No description provided for @createExcursionCategoryCulinary.
  ///
  /// In en, this message translates to:
  /// **'Culinary'**
  String get createExcursionCategoryCulinary;

  /// No description provided for @createExcursionCategoryWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get createExcursionCategoryWellness;

  /// No description provided for @createExcursionDetailedItinerary.
  ///
  /// In en, this message translates to:
  /// **'Detailed Itinerary'**
  String get createExcursionDetailedItinerary;

  /// No description provided for @createExcursionAddTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Add Time Slot'**
  String get createExcursionAddTimeSlot;

  /// No description provided for @createExcursionEditTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Edit Time Slot'**
  String get createExcursionEditTimeSlot;

  /// No description provided for @createExcursionItineraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add at least two route points. They will be shown to tourists in the excursion details.'**
  String get createExcursionItineraryEmpty;

  /// No description provided for @createExcursionAutosaveHint.
  ///
  /// In en, this message translates to:
  /// **'Progress is saved locally while you create the offer'**
  String get createExcursionAutosaveHint;

  /// No description provided for @createExcursionAutosaveRestored.
  ///
  /// In en, this message translates to:
  /// **'Local draft restored'**
  String get createExcursionAutosaveRestored;

  /// No description provided for @createExcursionDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get createExcursionDiscardTitle;

  /// No description provided for @createExcursionDiscardDescription.
  ///
  /// In en, this message translates to:
  /// **'Your excursion draft data will be lost. The form will open empty next time.'**
  String get createExcursionDiscardDescription;

  /// No description provided for @createExcursionDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave and discard'**
  String get createExcursionDiscardConfirm;

  /// No description provided for @createExcursionModeSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch route type?'**
  String get createExcursionModeSwitchTitle;

  /// No description provided for @createExcursionModeSwitchDescription.
  ///
  /// In en, this message translates to:
  /// **'Data from the current route type will be cleared. Other excursion details will stay in place.'**
  String get createExcursionModeSwitchDescription;

  /// No description provided for @createExcursionModeSwitchCancel.
  ///
  /// In en, this message translates to:
  /// **'Stay here'**
  String get createExcursionModeSwitchCancel;

  /// No description provided for @createExcursionModeSwitchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch and clear'**
  String get createExcursionModeSwitchConfirm;

  /// No description provided for @createExcursionItineraryValidation.
  ///
  /// In en, this message translates to:
  /// **'Fill in the route point time, title, and description'**
  String get createExcursionItineraryValidation;

  /// No description provided for @createExcursionItineraryMinSlotsValidation.
  ///
  /// In en, this message translates to:
  /// **'Add at least {count} route points'**
  String createExcursionItineraryMinSlotsValidation(Object count);

  /// No description provided for @createExcursionItineraryDescriptionMinLengthValidation.
  ///
  /// In en, this message translates to:
  /// **'Route point description must be at least {count} characters'**
  String createExcursionItineraryDescriptionMinLengthValidation(Object count);

  /// No description provided for @createExcursionStartOffsetValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter the route point start time'**
  String get createExcursionStartOffsetValidation;

  /// No description provided for @createExcursionItineraryTitleValidation.
  ///
  /// In en, this message translates to:
  /// **'Route point title must be at least 2 characters'**
  String get createExcursionItineraryTitleValidation;

  /// No description provided for @createExcursionOffsetMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'+{minutes}m'**
  String createExcursionOffsetMinutesShort(Object minutes);

  /// No description provided for @createExcursionOffsetHoursShort.
  ///
  /// In en, this message translates to:
  /// **'+{hours}h'**
  String createExcursionOffsetHoursShort(Object hours);

  /// No description provided for @createExcursionOffsetHoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'+{hours}h {minutes}m'**
  String createExcursionOffsetHoursMinutesShort(Object hours, Object minutes);

  /// No description provided for @createExcursionDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get createExcursionDurationLabel;

  /// No description provided for @createExcursionDurationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4 hours'**
  String get createExcursionDurationHint;

  /// No description provided for @createExcursionDurationUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get createExcursionDurationUnitLabel;

  /// No description provided for @createExcursionDurationUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get createExcursionDurationUnitMinutes;

  /// No description provided for @createExcursionDurationUnitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get createExcursionDurationUnitHours;

  /// No description provided for @createExcursionDurationUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get createExcursionDurationUnitDays;

  /// No description provided for @createExcursionDurationValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a duration of at least 15 minutes'**
  String get createExcursionDurationValidation;

  /// No description provided for @createExcursionMaxGroupSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Group Size'**
  String get createExcursionMaxGroupSizeLabel;

  /// No description provided for @createExcursionMaxGroupSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12'**
  String get createExcursionMaxGroupSizeHint;

  /// No description provided for @createExcursionGroupSizeValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a group size from 1 to 100'**
  String get createExcursionGroupSizeValidation;

  /// No description provided for @createExcursionLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages Spoken'**
  String get createExcursionLanguagesLabel;

  /// No description provided for @createExcursionLanguagesHint.
  ///
  /// In en, this message translates to:
  /// **'English, French, Japanese...'**
  String get createExcursionLanguagesHint;

  /// No description provided for @createExcursionLanguagesValidation.
  ///
  /// In en, this message translates to:
  /// **'Add at least one excursion language'**
  String get createExcursionLanguagesValidation;

  /// No description provided for @createExcursionLanguagesPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Select up to {count} languages'**
  String createExcursionLanguagesPickerHint(Object count);

  /// No description provided for @createExcursionLanguagesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Language or code'**
  String get createExcursionLanguagesSearchHint;

  /// No description provided for @createExcursionLanguagesNoResults.
  ///
  /// In en, this message translates to:
  /// **'Language not found'**
  String get createExcursionLanguagesNoResults;

  /// No description provided for @createExcursionLanguagesLimitValidation.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {count} languages'**
  String createExcursionLanguagesLimitValidation(Object count);

  /// No description provided for @createExcursionVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion Visibility'**
  String get createExcursionVisibilityTitle;

  /// No description provided for @createExcursionVisibilityPublicDescription.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone in the Inflap marketplace.'**
  String get createExcursionVisibilityPublicDescription;

  /// No description provided for @createExcursionVisibilityUnlistedDescription.
  ///
  /// In en, this message translates to:
  /// **'Only users with the direct URL can view and book this excursion.'**
  String get createExcursionVisibilityUnlistedDescription;

  /// No description provided for @createExcursionMeetingPointHint.
  ///
  /// In en, this message translates to:
  /// **'Enter meeting address or landmark...'**
  String get createExcursionMeetingPointHint;

  /// No description provided for @createExcursionSoulTitle.
  ///
  /// In en, this message translates to:
  /// **'Soul of the Journey'**
  String get createExcursionSoulTitle;

  /// No description provided for @createExcursionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Excursion Title'**
  String get createExcursionNameLabel;

  /// No description provided for @createExcursionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Almaty Mountain Escape'**
  String get createExcursionNameHint;

  /// No description provided for @createExcursionSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Short Summary'**
  String get createExcursionSummaryLabel;

  /// No description provided for @createExcursionSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'A concise promise for travelers'**
  String get createExcursionSummaryHint;

  /// No description provided for @createExcursionSummaryValidation.
  ///
  /// In en, this message translates to:
  /// **'Summary must be at least 3 characters'**
  String get createExcursionSummaryValidation;

  /// No description provided for @createExcursionSoulHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the soul of this journey, hidden details, and the feeling of being there...'**
  String get createExcursionSoulHint;

  /// No description provided for @createExcursionDescriptionValidation.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 20 characters'**
  String get createExcursionDescriptionValidation;

  /// No description provided for @createExcursionInvestmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Investment Per Person'**
  String get createExcursionInvestmentTitle;

  /// No description provided for @createExcursionCurrencyValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a currency code'**
  String get createExcursionCurrencyValidation;

  /// No description provided for @createCurrencyKzt.
  ///
  /// In en, this message translates to:
  /// **'tenge'**
  String get createCurrencyKzt;

  /// No description provided for @createCurrencyUsd.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get createCurrencyUsd;

  /// No description provided for @createCurrencyEur.
  ///
  /// In en, this message translates to:
  /// **'euro'**
  String get createCurrencyEur;

  /// No description provided for @createCurrencyRub.
  ///
  /// In en, this message translates to:
  /// **'ruble'**
  String get createCurrencyRub;

  /// No description provided for @createCurrencyGbp.
  ///
  /// In en, this message translates to:
  /// **'pound sterling'**
  String get createCurrencyGbp;

  /// No description provided for @createExcursionIncludedItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Included Items'**
  String get createExcursionIncludedItemsLabel;

  /// No description provided for @createExcursionIncludedItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated: Private SUV, picnic, tickets'**
  String get createExcursionIncludedItemsHint;

  /// No description provided for @createExcursionIncludedItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add exact items such as transport, meals, entrance tickets, or gear'**
  String get createExcursionIncludedItemsEmpty;

  /// No description provided for @createExcursionIncludedItemsEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'What is included'**
  String get createExcursionIncludedItemsEditorTitle;

  /// No description provided for @createExcursionIncludedItemsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get createExcursionIncludedItemsAdd;

  /// No description provided for @createExcursionIncludedItemsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get createExcursionIncludedItemsRemove;

  /// No description provided for @createExcursionIncludedItemsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get createExcursionIncludedItemsTypeLabel;

  /// No description provided for @createExcursionIncludedItemsValueLabel.
  ///
  /// In en, this message translates to:
  /// **'What exactly is included'**
  String get createExcursionIncludedItemsValueLabel;

  /// No description provided for @createExcursionIncludedItemsValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Private SUV transfer'**
  String get createExcursionIncludedItemsValueHint;

  /// No description provided for @createExcursionIncludedItemsValidation.
  ///
  /// In en, this message translates to:
  /// **'Fill in every included item or remove empty rows'**
  String get createExcursionIncludedItemsValidation;

  /// No description provided for @createExcursionIncludedTypeTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get createExcursionIncludedTypeTransport;

  /// No description provided for @createExcursionIncludedTypeFood.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get createExcursionIncludedTypeFood;

  /// No description provided for @createExcursionIncludedTypeTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get createExcursionIncludedTypeTickets;

  /// No description provided for @createExcursionIncludedTypeEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get createExcursionIncludedTypeEquipment;

  /// No description provided for @createExcursionIncludedTypeGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get createExcursionIncludedTypeGuide;

  /// No description provided for @createExcursionIncludedTypePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get createExcursionIncludedTypePhoto;

  /// No description provided for @createExcursionIncludedTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get createExcursionIncludedTypeOther;

  /// No description provided for @createExcursionStartOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Start after, min'**
  String get createExcursionStartOffsetLabel;

  /// No description provided for @createExcursionSlotDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration, min'**
  String get createExcursionSlotDurationLabel;

  /// No description provided for @createExcursionItineraryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get createExcursionItineraryTitleLabel;

  /// No description provided for @createExcursionItineraryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mountain Ascent'**
  String get createExcursionItineraryTitleHint;

  /// No description provided for @createExcursionItineraryDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createExcursionItineraryDescriptionLabel;

  /// No description provided for @createExcursionItineraryDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What happens during this part of the route'**
  String get createExcursionItineraryDescriptionHint;

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

  /// No description provided for @createActivityDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this activity?'**
  String get createActivityDiscardTitle;

  /// No description provided for @createActivityDiscardDescription.
  ///
  /// In en, this message translates to:
  /// **'Your draft changes will be lost if you leave now.'**
  String get createActivityDiscardDescription;

  /// No description provided for @createActivityDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get createActivityDiscardConfirm;

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

  /// No description provided for @createSubcategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get createSubcategoryLabel;

  /// No description provided for @createSubcategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a subcategory'**
  String get createSubcategoryHint;

  /// No description provided for @createSubcategoryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Subcategory'**
  String get createSubcategoryPickerTitle;

  /// No description provided for @createSubcategoryApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get createSubcategoryApply;

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

  /// No description provided for @createStartAtMonthLimitValidation.
  ///
  /// In en, this message translates to:
  /// **'Start date must be no later than {date}'**
  String createStartAtMonthLimitValidation(String date);

  /// No description provided for @createEndAtMonthLimitValidation.
  ///
  /// In en, this message translates to:
  /// **'End date must be no later than {date}'**
  String createEndAtMonthLimitValidation(String date);

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
  /// **'Visible to everyone on Inflap'**
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

  /// No description provided for @createVisibilityPasswordAsciiValidation.
  ///
  /// In en, this message translates to:
  /// **'Use only English letters, numbers, and symbols'**
  String get createVisibilityPasswordAsciiValidation;

  /// No description provided for @createVisibilityPasswordEditHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the current password'**
  String get createVisibilityPasswordEditHint;

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

  /// No description provided for @createAllowParticipantInvitesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow participants to invite friends'**
  String get createAllowParticipantInvitesLabel;

  /// No description provided for @createAllowParticipantInvitesHint.
  ///
  /// In en, this message translates to:
  /// **'The activity author can always invite their friends. Other users can invite only their own friends when this option is enabled.'**
  String get createAllowParticipantInvitesHint;

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
  /// **'Please enter a maximum between 1 and 100 participants'**
  String get createMaxParticipantsValidation;

  /// No description provided for @createMinParticipantsValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a minimum of at least 2 participants'**
  String get createMinParticipantsValidation;

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

  /// No description provided for @createMapLinkInvalidError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t detect coordinates from this link. Choose a point on our map or paste a link with coordinates from another map.'**
  String get createMapLinkInvalidError;

  /// No description provided for @createMapLinkResolvingError.
  ///
  /// In en, this message translates to:
  /// **'Detecting coordinates from this link. Please wait a few seconds.'**
  String get createMapLinkResolvingError;

  /// No description provided for @createMapLinkRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Add a map link or choose a point on our map.'**
  String get createMapLinkRequiredError;

  /// No description provided for @createMapEarlyStageNotice.
  ///
  /// In en, this message translates to:
  /// **'Our in-app map is still early-stage: paste a link from another map or place a point on our map for now. Soon we\'ll improve the map so you can choose the meeting point here without switching to other map apps.'**
  String get createMapEarlyStageNotice;

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

  /// No description provided for @createAuthorLocationMismatchHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting city differs from your current location. Keep it if this activity is planned for another place.'**
  String get createAuthorLocationMismatchHint;

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
  /// **'Meeting address can be changed until 1 hour before the activity starts'**
  String get editLocationLocked;

  /// No description provided for @editPriceRestrictionHint.
  ///
  /// In en, this message translates to:
  /// **'Price cannot be changed if other participants have already joined'**
  String get editPriceRestrictionHint;

  /// No description provided for @myActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Activities'**
  String get myActivitiesTitle;

  /// No description provided for @myStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myStoriesTitle;

  /// No description provided for @myStoryArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'My Stories'**
  String get myStoryArchiveTitle;

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

  /// No description provided for @myExcursionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Excursions'**
  String get myExcursionsTitle;

  /// No description provided for @myExcursionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Excursions, guides, and cities'**
  String get myExcursionsSearchHint;

  /// No description provided for @myExcursionsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion filters'**
  String get myExcursionsFilterTitle;

  /// No description provided for @myExcursionsReviewSuccess.
  ///
  /// In en, this message translates to:
  /// **'Review published'**
  String get myExcursionsReviewSuccess;

  /// No description provided for @myExcursionsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get myExcursionsSortLabel;

  /// No description provided for @myExcursionsSortDate.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get myExcursionsSortDate;

  /// No description provided for @myExcursionsSortPrice.
  ///
  /// In en, this message translates to:
  /// **'By price'**
  String get myExcursionsSortPrice;

  /// No description provided for @myExcursionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your excursions'**
  String get myExcursionsLoadFailed;

  /// No description provided for @myExcursionsBookedEmpty.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have booked excursions yet'**
  String get myExcursionsBookedEmpty;

  /// No description provided for @myExcursionsVisitedEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t visited any excursions yet'**
  String get myExcursionsVisitedEmpty;

  /// No description provided for @myExcursionsBookedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Booked excursions will appear here'**
  String get myExcursionsBookedEmptyHint;

  /// No description provided for @myExcursionsVisitedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'After a visit, you can leave a review here'**
  String get myExcursionsVisitedEmptyHint;

  /// No description provided for @myExcursionsBookedTab.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get myExcursionsBookedTab;

  /// No description provided for @myExcursionsVisitedTab.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get myExcursionsVisitedTab;

  /// No description provided for @myExcursionsGuideFallback.
  ///
  /// In en, this message translates to:
  /// **'Inflap guide'**
  String get myExcursionsGuideFallback;

  /// No description provided for @myExcursionsUntitled.
  ///
  /// In en, this message translates to:
  /// **'Excursion'**
  String get myExcursionsUntitled;

  /// No description provided for @myExcursionsGuideLine.
  ///
  /// In en, this message translates to:
  /// **'Guide: {guide}'**
  String myExcursionsGuideLine(Object guide);

  /// No description provided for @myExcursionsGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests: {count}'**
  String myExcursionsGuests(Object count);

  /// No description provided for @myExcursionsReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get myExcursionsReviewButton;

  /// No description provided for @myExcursionsReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get myExcursionsReviewed;

  /// No description provided for @myExcursionsEditGuestsButton.
  ///
  /// In en, this message translates to:
  /// **'Edit guests'**
  String get myExcursionsEditGuestsButton;

  /// No description provided for @myExcursionsEditGuestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit guests'**
  String get myExcursionsEditGuestsTitle;

  /// No description provided for @myExcursionsEditGuestsHint.
  ///
  /// In en, this message translates to:
  /// **'We will check available seats and update the booking without creating another one.'**
  String get myExcursionsEditGuestsHint;

  /// No description provided for @myExcursionsUpdateGuestsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Guest count updated'**
  String get myExcursionsUpdateGuestsSuccess;

  /// No description provided for @myExcursionsUpdateGuestsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update guest count. Check available seats and try again.'**
  String get myExcursionsUpdateGuestsFailed;

  /// No description provided for @myExcursionsGuestsAdditionalCharge.
  ///
  /// In en, this message translates to:
  /// **'Additional charge: {amount}'**
  String myExcursionsGuestsAdditionalCharge(Object amount);

  /// No description provided for @myExcursionsGuestsRefundDue.
  ///
  /// In en, this message translates to:
  /// **'Refund due: {amount}'**
  String myExcursionsGuestsRefundDue(Object amount);

  /// No description provided for @myExcursionsGuestsNoPaymentChange.
  ///
  /// In en, this message translates to:
  /// **'Price will not change'**
  String get myExcursionsGuestsNoPaymentChange;

  /// No description provided for @myExcursionsGuestsPaymentQuoteHint.
  ///
  /// In en, this message translates to:
  /// **'The estimate is calculated on the server. Real charges or refunds will be connected through the payment service.'**
  String get myExcursionsGuestsPaymentQuoteHint;

  /// No description provided for @myExcursionsGuestsQuoteLoading.
  ///
  /// In en, this message translates to:
  /// **'Calculating price change...'**
  String get myExcursionsGuestsQuoteLoading;

  /// No description provided for @myExcursionsGuestsQuoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate the price change. Check available seats and try again.'**
  String get myExcursionsGuestsQuoteFailed;

  /// No description provided for @myExcursionsPayAndSaveGuests.
  ///
  /// In en, this message translates to:
  /// **'Pay and save'**
  String get myExcursionsPayAndSaveGuests;

  /// No description provided for @myExcursionsRefundAndSaveGuests.
  ///
  /// In en, this message translates to:
  /// **'Refund and save'**
  String get myExcursionsRefundAndSaveGuests;

  /// No description provided for @myExcursionsCancelBookingButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get myExcursionsCancelBookingButton;

  /// No description provided for @myExcursionsCancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get myExcursionsCancelBookingTitle;

  /// No description provided for @myExcursionsCancelBookingHint.
  ///
  /// In en, this message translates to:
  /// **'We will cancel your place and show the guide that the booking was cancelled by you.'**
  String get myExcursionsCancelBookingHint;

  /// No description provided for @myExcursionsCancelQuoteLoading.
  ///
  /// In en, this message translates to:
  /// **'Calculating refund terms...'**
  String get myExcursionsCancelQuoteLoading;

  /// No description provided for @myExcursionsCancelQuoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate refund terms. Try again.'**
  String get myExcursionsCancelQuoteFailed;

  /// No description provided for @myExcursionsCancelBookingRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund: {amount} ({percent}%)'**
  String myExcursionsCancelBookingRefund(Object amount, int percent);

  /// No description provided for @myExcursionsCancelBookingNoRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund is not available'**
  String get myExcursionsCancelBookingNoRefund;

  /// No description provided for @myExcursionsCancelBookingRefundHint.
  ///
  /// In en, this message translates to:
  /// **'The server will fix the final refund amount. Real payment refund will be connected through the payment service.'**
  String get myExcursionsCancelBookingRefundHint;

  /// No description provided for @myExcursionsCancelPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get myExcursionsCancelPolicyTitle;

  /// No description provided for @myExcursionsCancelPolicyFull.
  ///
  /// In en, this message translates to:
  /// **'24+ hours before start: 100%'**
  String get myExcursionsCancelPolicyFull;

  /// No description provided for @myExcursionsCancelPolicySeventyFive.
  ///
  /// In en, this message translates to:
  /// **'12-24 hours before start: 75%'**
  String get myExcursionsCancelPolicySeventyFive;

  /// No description provided for @myExcursionsCancelPolicyHalf.
  ///
  /// In en, this message translates to:
  /// **'6-12 hours before start: 50%'**
  String get myExcursionsCancelPolicyHalf;

  /// No description provided for @myExcursionsCancelPolicyQuarter.
  ///
  /// In en, this message translates to:
  /// **'2-6 hours before start: 25%'**
  String get myExcursionsCancelPolicyQuarter;

  /// No description provided for @myExcursionsCancelPolicyZero.
  ///
  /// In en, this message translates to:
  /// **'Less than 2 hours before start: 0%'**
  String get myExcursionsCancelPolicyZero;

  /// No description provided for @myExcursionsCancelBookingReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get myExcursionsCancelBookingReasonLabel;

  /// No description provided for @myExcursionsCancelBookingReasonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: plans changed'**
  String get myExcursionsCancelBookingReasonPlaceholder;

  /// No description provided for @myExcursionsCancelBookingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get myExcursionsCancelBookingConfirm;

  /// No description provided for @myExcursionsCancelBookingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get myExcursionsCancelBookingSuccess;

  /// No description provided for @myExcursionsCancelBookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel booking'**
  String get myExcursionsCancelBookingFailed;

  /// No description provided for @myExcursionsCancelledWithRefund.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Refund: {amount} ({percent}%)'**
  String myExcursionsCancelledWithRefund(Object amount, int percent);

  /// No description provided for @myExcursionsCancelledWithoutRefund.
  ///
  /// In en, this message translates to:
  /// **'Cancelled without refund'**
  String get myExcursionsCancelledWithoutRefund;

  /// No description provided for @myExcursionsFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get myExcursionsFilterStatus;

  /// No description provided for @myExcursionsStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get myExcursionsStatusRequested;

  /// No description provided for @myExcursionsFilterReview.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get myExcursionsFilterReview;

  /// No description provided for @myExcursionsFilterReviewAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get myExcursionsFilterReviewAll;

  /// No description provided for @myExcursionsFilterUnreviewed.
  ///
  /// In en, this message translates to:
  /// **'Without review'**
  String get myExcursionsFilterUnreviewed;

  /// No description provided for @myExcursionsFilterReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get myExcursionsFilterReviewed;

  /// No description provided for @myExcursionsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate the excursion'**
  String get myExcursionsReviewTitle;

  /// No description provided for @myExcursionsReviewCommentError.
  ///
  /// In en, this message translates to:
  /// **'Write a short review'**
  String get myExcursionsReviewCommentError;

  /// No description provided for @myExcursionsReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish review'**
  String get myExcursionsReviewFailed;

  /// No description provided for @myExcursionsReviewDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete review'**
  String get myExcursionsReviewDeleteFailed;

  /// No description provided for @myExcursionsReviewRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get myExcursionsReviewRating;

  /// No description provided for @myExcursionsReviewHint.
  ///
  /// In en, this message translates to:
  /// **'What did you like, and what could be better?'**
  String get myExcursionsReviewHint;

  /// No description provided for @myExcursionsExcursionReviewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion review'**
  String get myExcursionsExcursionReviewSectionTitle;

  /// No description provided for @myExcursionsExcursionReviewSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rate the route, organization, and overall experience.'**
  String get myExcursionsExcursionReviewSectionSubtitle;

  /// No description provided for @myExcursionsExcursionReviewOptional.
  ///
  /// In en, this message translates to:
  /// **'Turn this off if you only want to rate the guide.'**
  String get myExcursionsExcursionReviewOptional;

  /// No description provided for @myExcursionsGuideReviewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide review'**
  String get myExcursionsGuideReviewSectionTitle;

  /// No description provided for @myExcursionsGuideReviewSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optionally rate the guide separately for future travelers.'**
  String get myExcursionsGuideReviewSectionSubtitle;

  /// No description provided for @myExcursionsGuideReviewRating.
  ///
  /// In en, this message translates to:
  /// **'Guide rating'**
  String get myExcursionsGuideReviewRating;

  /// No description provided for @myExcursionsGuideReviewHint.
  ///
  /// In en, this message translates to:
  /// **'How was the guide\'s communication, care, and storytelling?'**
  String get myExcursionsGuideReviewHint;

  /// No description provided for @myExcursionsGuideReviewOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional, but it helps the guide build a trusted profile.'**
  String get myExcursionsGuideReviewOptional;

  /// No description provided for @myExcursionsReviewSelectOneError.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one review to publish'**
  String get myExcursionsReviewSelectOneError;

  /// No description provided for @myExcursionsReviewDeleteExcursion.
  ///
  /// In en, this message translates to:
  /// **'Delete excursion review'**
  String get myExcursionsReviewDeleteExcursion;

  /// No description provided for @myExcursionsReviewDeleteGuide.
  ///
  /// In en, this message translates to:
  /// **'Delete guide review'**
  String get myExcursionsReviewDeleteGuide;

  /// No description provided for @myExcursionsReviewPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get myExcursionsReviewPublish;

  /// No description provided for @excursionReviewActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review actions'**
  String get excursionReviewActionsTitle;

  /// No description provided for @excursionReviewEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get excursionReviewEditAction;

  /// No description provided for @excursionReviewDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete review'**
  String get excursionReviewDeleteAction;

  /// No description provided for @excursionReviewEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get excursionReviewEditTitle;

  /// No description provided for @excursionReviewEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save review'**
  String get excursionReviewEditSave;

  /// No description provided for @excursionReviewUpdated.
  ///
  /// In en, this message translates to:
  /// **'Review updated'**
  String get excursionReviewUpdated;

  /// No description provided for @excursionReviewDeleted.
  ///
  /// In en, this message translates to:
  /// **'Review deleted'**
  String get excursionReviewDeleted;

  /// No description provided for @guideDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide Dashboard'**
  String get guideDashboardTitle;

  /// No description provided for @guideDashboardReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get guideDashboardReviewsTitle;

  /// No description provided for @guideDashboardExcursionReviewsTab.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get guideDashboardExcursionReviewsTab;

  /// No description provided for @guideDashboardDirectGuideReviewsTab.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guideDashboardDirectGuideReviewsTab;

  /// No description provided for @guideDashboardOffersStat.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get guideDashboardOffersStat;

  /// No description provided for @guideDashboardBookingsStat.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get guideDashboardBookingsStat;

  /// No description provided for @guideDashboardRevenueStat.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get guideDashboardRevenueStat;

  /// No description provided for @guideDashboardRatingStat.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get guideDashboardRatingStat;

  /// No description provided for @guideDashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Offers, guests, cities, and dates'**
  String get guideDashboardSearchHint;

  /// No description provided for @guideDashboardOffersTab.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get guideDashboardOffersTab;

  /// No description provided for @guideDashboardBookingsTab.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get guideDashboardBookingsTab;

  /// No description provided for @guideDashboardCompletedTab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get guideDashboardCompletedTab;

  /// No description provided for @guideDashboardActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get guideDashboardActiveTab;

  /// No description provided for @guideDashboardDraftTab.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get guideDashboardDraftTab;

  /// No description provided for @guideDashboardArchiveTab.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get guideDashboardArchiveTab;

  /// No description provided for @guideDashboardReviewTab.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get guideDashboardReviewTab;

  /// No description provided for @guideDashboardRejectedTab.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get guideDashboardRejectedTab;

  /// No description provided for @guideDashboardCancelledTab.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get guideDashboardCancelledTab;

  /// No description provided for @guideDashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load guide dashboard'**
  String get guideDashboardLoadFailed;

  /// No description provided for @guideDashboardOffersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active offers yet'**
  String get guideDashboardOffersEmpty;

  /// No description provided for @guideDashboardOffersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Publish your first excursion offer so travelers can book it.'**
  String get guideDashboardOffersEmptyHint;

  /// No description provided for @guideDashboardBookingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings'**
  String get guideDashboardBookingsEmpty;

  /// No description provided for @guideDashboardBookingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'New client bookings will appear here with date, guests, and payout amount.'**
  String get guideDashboardBookingsEmptyHint;

  /// No description provided for @guideDashboardCompletedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed excursions yet'**
  String get guideDashboardCompletedEmpty;

  /// No description provided for @guideDashboardCompletedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Finished excursions move here after their scheduled date.'**
  String get guideDashboardCompletedEmptyHint;

  /// No description provided for @guideDashboardDraftEmpty.
  ///
  /// In en, this message translates to:
  /// **'No draft offers'**
  String get guideDashboardDraftEmpty;

  /// No description provided for @guideDashboardDraftEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Saved drafts stay private until you send them for review.'**
  String get guideDashboardDraftEmptyHint;

  /// No description provided for @guideDashboardReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is under review'**
  String get guideDashboardReviewEmpty;

  /// No description provided for @guideDashboardReviewEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Offers waiting for moderation or publication will appear here.'**
  String get guideDashboardReviewEmptyHint;

  /// No description provided for @guideDashboardDirectGuideReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Direct guide reviews will appear here after travelers rate you separately.'**
  String get guideDashboardDirectGuideReviewsEmpty;

  /// No description provided for @guideDashboardArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get guideDashboardArchiveEmpty;

  /// No description provided for @guideDashboardArchiveEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Archive offers that are temporarily unavailable to remove them from active lists while keeping edit and publish access.'**
  String get guideDashboardArchiveEmptyHint;

  /// No description provided for @guideDashboardRejectedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rejected offers'**
  String get guideDashboardRejectedEmpty;

  /// No description provided for @guideDashboardRejectedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Offers declined during moderation will appear here with edit access.'**
  String get guideDashboardRejectedEmptyHint;

  /// No description provided for @guideDashboardCancelledEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cancelled bookings'**
  String get guideDashboardCancelledEmpty;

  /// No description provided for @guideDashboardCancelledEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Cancelled client bookings are kept here for history and guest follow-up.'**
  String get guideDashboardCancelledEmptyHint;

  /// No description provided for @guideDashboardCreateOffer.
  ///
  /// In en, this message translates to:
  /// **'Create offer'**
  String get guideDashboardCreateOffer;

  /// No description provided for @guideDashboardEditOffer.
  ///
  /// In en, this message translates to:
  /// **'Edit offer'**
  String get guideDashboardEditOffer;

  /// No description provided for @guideDashboardArchiveOffer.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get guideDashboardArchiveOffer;

  /// No description provided for @guideDashboardPublishOffer.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get guideDashboardPublishOffer;

  /// No description provided for @guideDashboardSubmitOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get guideDashboardSubmitOffer;

  /// No description provided for @guideDashboardDeleteDraftOffer.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get guideDashboardDeleteDraftOffer;

  /// No description provided for @guideDashboardDeleteDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete draft offer?'**
  String get guideDashboardDeleteDraftTitle;

  /// No description provided for @guideDashboardDeleteDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'This draft will be permanently removed. This action cannot be undone.'**
  String get guideDashboardDeleteDraftMessage;

  /// No description provided for @guideDashboardDeleteDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get guideDashboardDeleteDraftConfirm;

  /// No description provided for @guideDashboardDeleteDraftSuccess.
  ///
  /// In en, this message translates to:
  /// **'Draft offer deleted'**
  String get guideDashboardDeleteDraftSuccess;

  /// No description provided for @guideDashboardDeleteDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete draft offer'**
  String get guideDashboardDeleteDraftFailed;

  /// No description provided for @guideDashboardArchiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move offer to archive'**
  String get guideDashboardArchiveFailed;

  /// No description provided for @guideDashboardPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish offer'**
  String get guideDashboardPublishFailed;

  /// No description provided for @guideDashboardSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit offer for review'**
  String get guideDashboardSubmitFailed;

  /// No description provided for @guideDashboardViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get guideDashboardViewBooking;

  /// No description provided for @guideDashboardShowAttendanceQr.
  ///
  /// In en, this message translates to:
  /// **'Attendance QR'**
  String get guideDashboardShowAttendanceQr;

  /// No description provided for @guideDashboardAttendanceParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get guideDashboardAttendanceParticipants;

  /// No description provided for @guideDashboardAttendanceCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get guideDashboardAttendanceCheckedIn;

  /// No description provided for @guideDashboardAttendanceWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for check-in'**
  String get guideDashboardAttendanceWaiting;

  /// No description provided for @guideDashboardViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get guideDashboardViewDetails;

  /// No description provided for @guideDashboardCancelExcursion.
  ///
  /// In en, this message translates to:
  /// **'Cancel excursion'**
  String get guideDashboardCancelExcursion;

  /// No description provided for @guideDashboardCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this excursion?'**
  String get guideDashboardCancelTitle;

  /// No description provided for @guideDashboardCancelDescription.
  ///
  /// In en, this message translates to:
  /// **'We will cancel this slot for guests and show the amount that must be refunded for affected bookings.'**
  String get guideDashboardCancelDescription;

  /// No description provided for @guideDashboardCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get guideDashboardCancelReasonLabel;

  /// No description provided for @guideDashboardCancelReasonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: the guide is sick or weather makes the route unsafe'**
  String get guideDashboardCancelReasonPlaceholder;

  /// No description provided for @guideDashboardCancelReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a cancellation reason'**
  String get guideDashboardCancelReasonRequired;

  /// No description provided for @guideDashboardCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get guideDashboardCancelConfirm;

  /// No description provided for @guideDashboardCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Excursion cancelled'**
  String get guideDashboardCancelSuccess;

  /// No description provided for @guideDashboardCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel excursion'**
  String get guideDashboardCancelFailed;

  /// No description provided for @guideDashboardCancelNoSlot.
  ///
  /// In en, this message translates to:
  /// **'This booking does not have a schedule slot to cancel'**
  String get guideDashboardCancelNoSlot;

  /// No description provided for @guideDashboardRefundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund to guests: {amount}'**
  String guideDashboardRefundAmount(Object amount);

  /// No description provided for @guideDashboardCancelledByTourist.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by tourist'**
  String get guideDashboardCancelledByTourist;

  /// No description provided for @guideDashboardCancelledByGuide.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by guide'**
  String get guideDashboardCancelledByGuide;

  /// No description provided for @guideDashboardCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String guideDashboardCancellationReason(Object reason);

  /// No description provided for @guideDashboardBookingSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get guideDashboardBookingSheetTitle;

  /// No description provided for @guideDashboardBookingAuthorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking authors'**
  String get guideDashboardBookingAuthorsTitle;

  /// No description provided for @guideDashboardAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get guideDashboardAdults;

  /// No description provided for @guideDashboardChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get guideDashboardChildren;

  /// No description provided for @guideDashboardTotalGuests.
  ///
  /// In en, this message translates to:
  /// **'Total guests'**
  String get guideDashboardTotalGuests;

  /// No description provided for @guideDashboardGuestBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Adults: {adults} · Children: {children} · Total: {total}'**
  String guideDashboardGuestBreakdown(
    Object adults,
    Object children,
    Object total,
  );

  /// No description provided for @guideDashboardStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get guideDashboardStatusActive;

  /// No description provided for @guideDashboardStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get guideDashboardStatusDraft;

  /// No description provided for @guideDashboardStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get guideDashboardStatusArchived;

  /// No description provided for @guideDashboardStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get guideDashboardStatusReview;

  /// No description provided for @guideDashboardStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get guideDashboardStatusRejected;

  /// No description provided for @guideDashboardStatusBooked.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get guideDashboardStatusBooked;

  /// No description provided for @guideDashboardStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get guideDashboardStatusCompleted;

  /// No description provided for @guideDashboardStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get guideDashboardStatusCancelled;

  /// No description provided for @guideDashboardFlexibleGroup.
  ///
  /// In en, this message translates to:
  /// **'Flexible group'**
  String get guideDashboardFlexibleGroup;

  /// No description provided for @guideDashboardMaxGuests.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} guests'**
  String guideDashboardMaxGuests(Object count);

  /// No description provided for @guideDashboardBookingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bookings'**
  String guideDashboardBookingCount(Object count);

  /// No description provided for @excursionReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews after excursions'**
  String get excursionReviewsTitle;

  /// No description provided for @excursionReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no reviews for this excursion yet'**
  String get excursionReviewsEmpty;

  /// No description provided for @excursionReviewViaGuide.
  ///
  /// In en, this message translates to:
  /// **'Via guide: {guide}'**
  String excursionReviewViaGuide(Object guide);

  /// No description provided for @excursionReviewSourcePlaceBadge.
  ///
  /// In en, this message translates to:
  /// **'Review based on a visited excursion'**
  String get excursionReviewSourcePlaceBadge;

  /// No description provided for @activityReviewsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get activityReviewsSectionTitle;

  /// No description provided for @activityReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity reviews'**
  String get activityReviewsTitle;

  /// No description provided for @activityOrganizerReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Organizer reviews'**
  String get activityOrganizerReviewsTitle;

  /// No description provided for @activityReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no reviews for this activity yet'**
  String get activityReviewsEmpty;

  /// No description provided for @activityReviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load activity reviews'**
  String get activityReviewsLoadFailed;

  /// No description provided for @activityReviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate the activity'**
  String get activityReviewSheetTitle;

  /// No description provided for @activityReviewActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityReviewActivityLabel;

  /// No description provided for @activityReviewOrganizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get activityReviewOrganizerLabel;

  /// No description provided for @activityReviewWriteButton.
  ///
  /// In en, this message translates to:
  /// **'Leave review'**
  String get activityReviewWriteButton;

  /// No description provided for @activityReviewEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get activityReviewEditButton;

  /// No description provided for @activityReviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reviews are available only to checked-in participants after the activity is completed.'**
  String get activityReviewUnavailable;

  /// No description provided for @activityReviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Review saved'**
  String get activityReviewSaved;

  /// No description provided for @activityReviewSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save review'**
  String get activityReviewSaveFailed;

  /// No description provided for @activityReviewPublishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish review?'**
  String get activityReviewPublishConfirmTitle;

  /// No description provided for @activityReviewPublishConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'After publishing, your activity and organizer ratings will be visible in reviews.'**
  String get activityReviewPublishConfirmDescription;

  /// No description provided for @activityReviewPublishConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Publish review'**
  String get activityReviewPublishConfirmButton;

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

  /// No description provided for @activityReachabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Can I make it?'**
  String get activityReachabilityTitle;

  /// No description provided for @activityReachabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check walking ETA from your current location before you head out.'**
  String get activityReachabilitySubtitle;

  /// No description provided for @activityReachabilityCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check ETA'**
  String get activityReachabilityCheckButton;

  /// No description provided for @activityReachabilityRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get activityReachabilityRetryButton;

  /// No description provided for @activityReachabilityOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get activityReachabilityOnTime;

  /// No description provided for @activityReachabilityLate.
  ///
  /// In en, this message translates to:
  /// **'Late risk'**
  String get activityReachabilityLate;

  /// No description provided for @activityReachabilityArriveBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Arrive about {minutes} min before start'**
  String activityReachabilityArriveBeforeStart(Object minutes);

  /// No description provided for @activityReachabilityArriveAfterStart.
  ///
  /// In en, this message translates to:
  /// **'Route arrives about {minutes} min after start'**
  String activityReachabilityArriveAfterStart(Object minutes);

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
  /// **'Activities, hosts, or cities'**
  String get activitiesSearchHint;

  /// No description provided for @activitiesFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get activitiesFiltersTitle;

  /// No description provided for @activitiesFilterCountrySection.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get activitiesFilterCountrySection;

  /// No description provided for @activitiesFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get activitiesFilterCountryAll;

  /// No description provided for @activitiesFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Country, code, or phone'**
  String get activitiesFilterCountrySearchHint;

  /// No description provided for @activitiesFilterCountryNoResults.
  ///
  /// In en, this message translates to:
  /// **'Country not found'**
  String get activitiesFilterCountryNoResults;

  /// No description provided for @activitiesSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get activitiesSortLabel;

  /// No description provided for @activitiesSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get activitiesSortDate;

  /// No description provided for @activitiesSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get activitiesSortPrice;

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

  /// No description provided for @activitiesFilterStartDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'15.05.2026'**
  String get activitiesFilterStartDatePlaceholder;

  /// No description provided for @activitiesFilterEndDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'22.05.2026'**
  String get activitiesFilterEndDatePlaceholder;

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
  /// **'Activities'**
  String get activitiesDiscoverTitle;

  /// No description provided for @activitiesNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities nearby'**
  String get activitiesNearbyTitle;

  /// No description provided for @activitiesNearbyMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Activities do not have meeting points yet'**
  String get activitiesNearbyMapEmpty;

  /// No description provided for @activitiesFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities match these filters'**
  String get activitiesFilteredEmptyTitle;

  /// No description provided for @activitiesFilteredEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try widening the category, date range, pricing filters, or choose another city'**
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
  /// **'This is not an Inflap activity QR'**
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
  /// **'You are not a participant of this activity'**
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

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @backButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButtonLabel;

  /// No description provided for @storiesDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get storiesDiscoverTitle;

  /// No description provided for @storiesNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get storiesNavLabel;

  /// No description provided for @storiesActivitiesNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get storiesActivitiesNavLabel;

  /// No description provided for @storySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Posts, authors, or places'**
  String get storySearchHint;

  /// No description provided for @storySearchCompactHint.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get storySearchCompactHint;

  /// No description provided for @storyFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get storyFiltersTitle;

  /// No description provided for @storyFiltersActiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Selected filters'**
  String get storyFiltersActiveSummary;

  /// No description provided for @storyFilterFormat.
  ///
  /// In en, this message translates to:
  /// **'Material type'**
  String get storyFilterFormat;

  /// No description provided for @storyFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get storyFilterCategory;

  /// No description provided for @storyFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get storyFilterCountry;

  /// No description provided for @storyFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get storyFilterCountryAll;

  /// No description provided for @storyFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Country, code, or phone'**
  String get storyFilterCountrySearchHint;

  /// No description provided for @storyFilterCountryNoResults.
  ///
  /// In en, this message translates to:
  /// **'Country not found'**
  String get storyFilterCountryNoResults;

  /// No description provided for @storyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storyFilterAll;

  /// No description provided for @storiesShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show {count, plural, =0{0 posts} =1{1 post} other{{count} posts}}'**
  String storiesShowResults(num count);

  /// No description provided for @storySortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get storySortLabel;

  /// No description provided for @storySortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get storySortDate;

  /// No description provided for @storySortViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get storySortViews;

  /// No description provided for @storySortComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get storySortComments;

  /// No description provided for @storyCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Share a post'**
  String get storyCreateCta;

  /// No description provided for @storyCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create the first post'**
  String get storyCreateFirst;

  /// No description provided for @storyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get storyEmptyTitle;

  /// No description provided for @storyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to publish a travel note, local guide, or visual essay.'**
  String get storyEmptySubtitle;

  /// No description provided for @storyEmptyAuthenticatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a post, article, guide, or visual essay to start the feed.'**
  String get storyEmptyAuthenticatedSubtitle;

  /// No description provided for @storyFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts match your filters'**
  String get storyFilteredEmptyTitle;

  /// No description provided for @storyFilteredEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different search, country, city, or category.'**
  String get storyFilteredEmptySubtitle;

  /// No description provided for @storyResetFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get storyResetFiltersAction;

  /// No description provided for @storyLoginCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Log in to create'**
  String get storyLoginCreateAction;

  /// No description provided for @myStoriesDraftsTab.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get myStoriesDraftsTab;

  /// No description provided for @myStoriesPendingReviewTab.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get myStoriesPendingReviewTab;

  /// No description provided for @myStoriesPublishedTab.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get myStoriesPublishedTab;

  /// No description provided for @myStoriesArchivedTab.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get myStoriesArchivedTab;

  /// No description provided for @myStoriesDraftEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet'**
  String get myStoriesDraftEmptyTitle;

  /// No description provided for @myStoriesDraftEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save ideas as drafts before publishing them to the posts feed.'**
  String get myStoriesDraftEmptySubtitle;

  /// No description provided for @myStoriesPendingReviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts in review'**
  String get myStoriesPendingReviewEmptyTitle;

  /// No description provided for @myStoriesPendingReviewEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Posts waiting for moderator review will appear here.'**
  String get myStoriesPendingReviewEmptySubtitle;

  /// No description provided for @myStoriesPublishedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No published posts yet'**
  String get myStoriesPublishedEmptyTitle;

  /// No description provided for @myStoriesPublishedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Published posts, guides, articles, and visual essays will appear here.'**
  String get myStoriesPublishedEmptySubtitle;

  /// No description provided for @myStoriesArchivedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived posts yet'**
  String get myStoriesArchivedEmptyTitle;

  /// No description provided for @myStoriesArchivedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Archived posts are kept here for history and reuse.'**
  String get myStoriesArchivedEmptySubtitle;

  /// No description provided for @myStoriesCreateDraftAction.
  ///
  /// In en, this message translates to:
  /// **'Create a draft'**
  String get myStoriesCreateDraftAction;

  /// No description provided for @storyArchiveActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get storyArchiveActiveTab;

  /// No description provided for @storyArchiveArchiveTab.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get storyArchiveArchiveTab;

  /// No description provided for @storyArchiveActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These are your stories that are still visible to other users.'**
  String get storyArchiveActiveSubtitle;

  /// No description provided for @storyArchiveActiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active stories yet'**
  String get storyArchiveActiveEmptyTitle;

  /// No description provided for @storyArchiveActiveEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture a photo or video story to keep it here for 24 hours.'**
  String get storyArchiveActiveEmptySubtitle;

  /// No description provided for @storyArchiveActiveUntilPrefix.
  ///
  /// In en, this message translates to:
  /// **'Active until'**
  String get storyArchiveActiveUntilPrefix;

  /// No description provided for @storyArchiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stories live for 24 hours, then stay here for you.'**
  String get storyArchiveSubtitle;

  /// No description provided for @storyArchiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived stories yet'**
  String get storyArchiveEmptyTitle;

  /// No description provided for @storyArchiveEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your camera stories will appear here after 24 hours.'**
  String get storyArchiveEmptySubtitle;

  /// No description provided for @storyArchiveLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load stories'**
  String get storyArchiveLoadFailedTitle;

  /// No description provided for @storyArchiveLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the connection and try again.'**
  String get storyArchiveLoadFailedMessage;

  /// No description provided for @storyArchiveRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get storyArchiveRetryAction;

  /// No description provided for @storyArchiveLoadMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get storyArchiveLoadMoreAction;

  /// No description provided for @storyArchiveExpiredPrefix.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get storyArchiveExpiredPrefix;

  /// No description provided for @storyStateSeenLabel.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get storyStateSeenLabel;

  /// No description provided for @storyStateExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get storyStateExpiredLabel;

  /// No description provided for @storyStatePendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get storyStatePendingLabel;

  /// No description provided for @storyStateHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get storyStateHiddenLabel;

  /// No description provided for @storyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts'**
  String get storyLoadFailed;

  /// No description provided for @storyViewsSuffix.
  ///
  /// In en, this message translates to:
  /// **'views'**
  String get storyViewsSuffix;

  /// No description provided for @storyCategoryJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get storyCategoryJournal;

  /// No description provided for @storyCategoryGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get storyCategoryGuide;

  /// No description provided for @storyCategoryPhotoEssay.
  ///
  /// In en, this message translates to:
  /// **'Photo Essay'**
  String get storyCategoryPhotoEssay;

  /// No description provided for @storyCategoryCulinary.
  ///
  /// In en, this message translates to:
  /// **'Culinary'**
  String get storyCategoryCulinary;

  /// No description provided for @storyFormatStory.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get storyFormatStory;

  /// No description provided for @storyFormatGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get storyFormatGuide;

  /// No description provided for @storyFormatPhotoEssay.
  ///
  /// In en, this message translates to:
  /// **'Photo Essay'**
  String get storyFormatPhotoEssay;

  /// No description provided for @storyFormatArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get storyFormatArticle;

  /// No description provided for @storyFormatCulinary.
  ///
  /// In en, this message translates to:
  /// **'Culinary'**
  String get storyFormatCulinary;

  /// No description provided for @storyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Post details'**
  String get storyDetailsTitle;

  /// No description provided for @storyLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Post link copied'**
  String get storyLinkCopied;

  /// No description provided for @storyShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the share sheet. Please try again.'**
  String get storyShareFailed;

  /// No description provided for @storyReportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get storyReportAction;

  /// No description provided for @storyReportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get storyReportSending;

  /// No description provided for @storyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get storyReportTitle;

  /// No description provided for @storyReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what is wrong. Reports help moderators keep travel content safe and useful.'**
  String get storyReportSubtitle;

  /// No description provided for @storyReportDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get storyReportDetailsLabel;

  /// No description provided for @storyReportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add context for moderators'**
  String get storyReportDetailsHint;

  /// No description provided for @storyReportSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get storyReportSubmitAction;

  /// No description provided for @storyReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We sent this post to moderation.'**
  String get storyReportSubmitted;

  /// No description provided for @storyReportAutoHidden.
  ///
  /// In en, this message translates to:
  /// **'Thanks. This post is hidden while moderators review it.'**
  String get storyReportAutoHidden;

  /// No description provided for @storyReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or misleading'**
  String get storyReportReasonSpam;

  /// No description provided for @storyReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get storyReportReasonHarassment;

  /// No description provided for @storyReportReasonHate.
  ///
  /// In en, this message translates to:
  /// **'Hate or discrimination'**
  String get storyReportReasonHate;

  /// No description provided for @storyReportReasonSexualContent.
  ///
  /// In en, this message translates to:
  /// **'Sexual content'**
  String get storyReportReasonSexualContent;

  /// No description provided for @storyReportReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or graphic content'**
  String get storyReportReasonViolence;

  /// No description provided for @storyReportReasonMisinformation.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get storyReportReasonMisinformation;

  /// No description provided for @storyReportReasonIllegal.
  ///
  /// In en, this message translates to:
  /// **'Illegal activity'**
  String get storyReportReasonIllegal;

  /// No description provided for @storyReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storyReportReasonOther;

  /// No description provided for @storyAuthorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get storyAuthorLabel;

  /// No description provided for @storyFollowAction.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get storyFollowAction;

  /// No description provided for @storyFollowingAction.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get storyFollowingAction;

  /// No description provided for @storyStatViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get storyStatViews;

  /// No description provided for @storyStatLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get storyStatLikes;

  /// No description provided for @storyStatComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get storyStatComments;

  /// No description provided for @storyStatShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get storyStatShares;

  /// No description provided for @storyTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get storyTagsLabel;

  /// No description provided for @storyCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a thoughtful comment'**
  String get storyCommentHint;

  /// No description provided for @storyCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get storyCommentsTitle;

  /// No description provided for @storyCommentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation.'**
  String get storyCommentsEmpty;

  /// No description provided for @storyCommentRateLimit.
  ///
  /// In en, this message translates to:
  /// **'You can leave only one comment every 3 hours.'**
  String get storyCommentRateLimit;

  /// No description provided for @storyCommentCooldownUntil.
  ///
  /// In en, this message translates to:
  /// **'You can leave the next comment after {time}.'**
  String storyCommentCooldownUntil(Object time);

  /// No description provided for @storyCommentLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Comment link copied'**
  String get storyCommentLinkCopied;

  /// No description provided for @storyCommentShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the comment share sheet. Please try again.'**
  String get storyCommentShareFailed;

  /// No description provided for @storyLikeActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the like. Please try again.'**
  String get storyLikeActionFailed;

  /// No description provided for @storyCommentEditingTitle.
  ///
  /// In en, this message translates to:
  /// **'Editing comment'**
  String get storyCommentEditingTitle;

  /// No description provided for @storyCommentSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get storyCommentSaveAction;

  /// No description provided for @storyCommentShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get storyCommentShareAction;

  /// No description provided for @storyDeleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get storyDeleteCommentTitle;

  /// No description provided for @storyDeleteCommentMessage.
  ///
  /// In en, this message translates to:
  /// **'This comment will be permanently removed.'**
  String get storyDeleteCommentMessage;

  /// No description provided for @storyDeleteCommentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storyDeleteCommentAction;

  /// No description provided for @storyRelatedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Keep Exploring'**
  String get storyRelatedEyebrow;

  /// No description provided for @storyRelatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Related posts'**
  String get storyRelatedTitle;

  /// No description provided for @storyRelatedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No related posts yet'**
  String get storyRelatedEmpty;

  /// No description provided for @storyViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get storyViewAll;

  /// No description provided for @storyEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get storyEditAction;

  /// No description provided for @storyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get storyDeleteTitle;

  /// No description provided for @storyDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The post will be removed from public feed.'**
  String get storyDeleteMessage;

  /// No description provided for @storyDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storyDeleteAction;

  /// No description provided for @storyCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Story'**
  String get storyCreateTitle;

  /// No description provided for @storyContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get storyContinueAction;

  /// No description provided for @storyUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update Story'**
  String get storyUpdateAction;

  /// No description provided for @storyPublishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish Story'**
  String get storyPublishAction;

  /// No description provided for @storySaveDraftAction.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get storySaveDraftAction;

  /// No description provided for @storySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save story'**
  String get storySaveFailed;

  /// No description provided for @storyCoverUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Cover Image'**
  String get storyCoverUploadTitle;

  /// No description provided for @storyCoverUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High-resolution cinematic landscape preferred'**
  String get storyCoverUploadSubtitle;

  /// No description provided for @storyCoverRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a cover image'**
  String get storyCoverRequired;

  /// No description provided for @storyCoverUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This image format is not supported'**
  String get storyCoverUnsupported;

  /// No description provided for @storyCoverTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Cover image is too large. Use a file up to 20 MB.'**
  String get storyCoverTooLarge;

  /// No description provided for @storyCoverUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload cover image'**
  String get storyCoverUploadFailed;

  /// No description provided for @storyTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Story Title'**
  String get storyTitleLabel;

  /// No description provided for @storyTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunset Yoga by the Pier'**
  String get storyTitleHint;

  /// No description provided for @storyTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a story title'**
  String get storyTitleRequired;

  /// No description provided for @storyTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'The title must not exceed {count} characters'**
  String storyTitleTooLong(Object count);

  /// No description provided for @storyPlacePrompt.
  ///
  /// In en, this message translates to:
  /// **'Where did this story take place?'**
  String get storyPlacePrompt;

  /// No description provided for @storyPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'City or country'**
  String get storyPlaceHint;

  /// No description provided for @storyCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get storyCountryHint;

  /// No description provided for @storyCityHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get storyCityHint;

  /// No description provided for @storyTagsFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get storyTagsFieldLabel;

  /// No description provided for @storyTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get storyTagHint;

  /// No description provided for @storyTagsLimit.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 8 tags'**
  String get storyTagsLimit;

  /// No description provided for @storyCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get storyCategoryLabel;

  /// No description provided for @storyCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a story category'**
  String get storyCategoryRequired;

  /// No description provided for @storyContentHint.
  ///
  /// In en, this message translates to:
  /// **'Start your narrative here...'**
  String get storyContentHint;

  /// No description provided for @storyContinueSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Continue the story here...'**
  String get storyContinueSectionHint;

  /// No description provided for @storyContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Write the story body'**
  String get storyContentRequired;

  /// No description provided for @storyContentTooLong.
  ///
  /// In en, this message translates to:
  /// **'The story body must not exceed {count} characters'**
  String storyContentTooLong(Object count);

  /// No description provided for @storyCharacterCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Character Count'**
  String get storyCharacterCountLabel;

  /// No description provided for @storyInlineImageAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get storyInlineImageAddAction;

  /// No description provided for @storyInlineImageHint.
  ///
  /// In en, this message translates to:
  /// **'Images will appear between story paragraphs.'**
  String get storyInlineImageHint;

  /// No description provided for @storyContinueSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue the text below or add more photos.'**
  String get storyContinueSectionLabel;

  /// No description provided for @storyInlineImageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This image format is not supported for story content.'**
  String get storyInlineImageUnsupported;

  /// No description provided for @storyInlineImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This image is too large. Choose a file up to 20 MB.'**
  String get storyInlineImageTooLarge;

  /// No description provided for @storyInlineImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload the image into the story. Please try again.'**
  String get storyInlineImageUploadFailed;

  /// No description provided for @storyAiHintUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI writing hints are not available yet'**
  String get storyAiHintUnavailable;

  /// No description provided for @storyWritersNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Writer\'s Note'**
  String get storyWritersNoteTitle;

  /// No description provided for @storyWritersNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Try starting with a sensory detail. Instead of “I arrived in Tokyo,” describe the neon glow reflecting off the damp pavement in Shibuya.'**
  String get storyWritersNoteBody;

  /// No description provided for @storyEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Post editor'**
  String get storyEditorTitle;

  /// No description provided for @storyEditorQuickPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick post'**
  String get storyEditorQuickPostTitle;

  /// No description provided for @storyEditorQuickPostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a short update, question, or local tip with the community.'**
  String get storyEditorQuickPostSubtitle;

  /// No description provided for @storyEditorQuickPostHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to share?'**
  String get storyEditorQuickPostHint;

  /// No description provided for @storyEditorLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading story'**
  String get storyEditorLoading;

  /// No description provided for @storyEditorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load story for editing.'**
  String get storyEditorLoadFailed;

  /// No description provided for @storyEditorEditMode.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get storyEditorEditMode;

  /// No description provided for @storyEditorPreviewMode.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get storyEditorPreviewMode;

  /// No description provided for @storyEditorRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover unsaved draft?'**
  String get storyEditorRecoveryTitle;

  /// No description provided for @storyEditorRecoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'A local recovery copy is available for this story.'**
  String get storyEditorRecoveryMessage;

  /// No description provided for @storyEditorRecoveryDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get storyEditorRecoveryDiscard;

  /// No description provided for @storyEditorRecoveryRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get storyEditorRecoveryRestore;

  /// No description provided for @storyEditorDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard post changes?'**
  String get storyEditorDiscardChangesTitle;

  /// No description provided for @storyEditorDiscardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Unsaved edits may be lost.'**
  String get storyEditorDiscardChangesMessage;

  /// No description provided for @storyEditorKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get storyEditorKeepEditing;

  /// No description provided for @storyEditorMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Publication setup'**
  String get storyEditorMetadataTitle;

  /// No description provided for @storyEditorTitleFieldHint.
  ///
  /// In en, this message translates to:
  /// **'A precise, searchable title'**
  String get storyEditorTitleFieldHint;

  /// No description provided for @storyEditorTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get storyEditorTemplateAction;

  /// No description provided for @storyEditorTemplateSemantic.
  ///
  /// In en, this message translates to:
  /// **'Choose story template'**
  String get storyEditorTemplateSemantic;

  /// No description provided for @storyEditorTemplatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a template'**
  String get storyEditorTemplatePlaceholder;

  /// No description provided for @storyEditorTemplateWeekendGuide.
  ///
  /// In en, this message translates to:
  /// **'Weekend guide'**
  String get storyEditorTemplateWeekendGuide;

  /// No description provided for @storyEditorTemplatePhotoEssay.
  ///
  /// In en, this message translates to:
  /// **'Photo essay'**
  String get storyEditorTemplatePhotoEssay;

  /// No description provided for @storyEditorTemplateFoodNotes.
  ///
  /// In en, this message translates to:
  /// **'Food notes'**
  String get storyEditorTemplateFoodNotes;

  /// No description provided for @storyEditorTemplateCityWalk.
  ///
  /// In en, this message translates to:
  /// **'City walk'**
  String get storyEditorTemplateCityWalk;

  /// No description provided for @storyEditorTemplateHiddenGems.
  ///
  /// In en, this message translates to:
  /// **'Hidden gems'**
  String get storyEditorTemplateHiddenGems;

  /// No description provided for @storyEditorTemplatePracticalTips.
  ///
  /// In en, this message translates to:
  /// **'Practical tips'**
  String get storyEditorTemplatePracticalTips;

  /// No description provided for @storyEditorTemplateCultureRoute.
  ///
  /// In en, this message translates to:
  /// **'Culture route'**
  String get storyEditorTemplateCultureRoute;

  /// No description provided for @storyEditorTemplateWeekendHeading.
  ///
  /// In en, this message translates to:
  /// **'Weekend plan'**
  String get storyEditorTemplateWeekendHeading;

  /// No description provided for @storyEditorTemplateWeekendList.
  ///
  /// In en, this message translates to:
  /// **'Morning stop\nLocal food\nEvening view'**
  String get storyEditorTemplateWeekendList;

  /// No description provided for @storyEditorTemplatePhotoHeading.
  ///
  /// In en, this message translates to:
  /// **'Photo story'**
  String get storyEditorTemplatePhotoHeading;

  /// No description provided for @storyEditorTemplateFoodHeading.
  ///
  /// In en, this message translates to:
  /// **'Where to eat'**
  String get storyEditorTemplateFoodHeading;

  /// No description provided for @storyEditorTemplateFoodParagraph.
  ///
  /// In en, this message translates to:
  /// **'Describe the dish, price range, and best time to visit.'**
  String get storyEditorTemplateFoodParagraph;

  /// No description provided for @storyEditorTemplateCityWalkHeading.
  ///
  /// In en, this message translates to:
  /// **'Walking route'**
  String get storyEditorTemplateCityWalkHeading;

  /// No description provided for @storyEditorTemplateCityWalkList.
  ///
  /// In en, this message translates to:
  /// **'Starting point\nMain street\nPause spot\nFinal view'**
  String get storyEditorTemplateCityWalkList;

  /// No description provided for @storyEditorTemplateCityWalkParagraph.
  ///
  /// In en, this message translates to:
  /// **'Add distance, approximate timing, and the easiest way to reach the start.'**
  String get storyEditorTemplateCityWalkParagraph;

  /// No description provided for @storyEditorTemplateHiddenGemsHeading.
  ///
  /// In en, this message translates to:
  /// **'Places not everyone knows'**
  String get storyEditorTemplateHiddenGemsHeading;

  /// No description provided for @storyEditorTemplateHiddenGemsList.
  ///
  /// In en, this message translates to:
  /// **'Why it is worth a stop\nWhen it is quiet\nWhat to see nearby'**
  String get storyEditorTemplateHiddenGemsList;

  /// No description provided for @storyEditorTemplateHiddenGemsCallout.
  ///
  /// In en, this message translates to:
  /// **'Add practical details: entry, schedule, safety, cash, or reservation notes.'**
  String get storyEditorTemplateHiddenGemsCallout;

  /// No description provided for @storyEditorTemplatePracticalTipsHeading.
  ///
  /// In en, this message translates to:
  /// **'Good to know before the trip'**
  String get storyEditorTemplatePracticalTipsHeading;

  /// No description provided for @storyEditorTemplatePracticalTipsList.
  ///
  /// In en, this message translates to:
  /// **'When to go\nHow to get there\nBudget to plan\nWhat to bring'**
  String get storyEditorTemplatePracticalTipsList;

  /// No description provided for @storyEditorTemplatePracticalTipsCallout.
  ///
  /// In en, this message translates to:
  /// **'Add an honest tip that saves time or helps avoid a common mistake.'**
  String get storyEditorTemplatePracticalTipsCallout;

  /// No description provided for @storyEditorTemplateCultureRouteHeading.
  ///
  /// In en, this message translates to:
  /// **'Culture route'**
  String get storyEditorTemplateCultureRouteHeading;

  /// No description provided for @storyEditorTemplateCultureRouteParagraph.
  ///
  /// In en, this message translates to:
  /// **'Explain which traditions, buildings, museums, or local stories help readers understand this place.'**
  String get storyEditorTemplateCultureRouteParagraph;

  /// No description provided for @storyEditorTemplateCultureRouteQuote.
  ///
  /// In en, this message translates to:
  /// **'Add a phrase, observation, or short fact that sets the mood for the route.'**
  String get storyEditorTemplateCultureRouteQuote;

  /// No description provided for @storyEditorTemplateConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply new story structure?'**
  String get storyEditorTemplateConflictTitle;

  /// No description provided for @storyEditorTemplateConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'This structure suggests {format} / {category}. Choose how to apply it without losing your draft.'**
  String storyEditorTemplateConflictMessage(Object format, Object category);

  /// No description provided for @storyEditorTemplateConflictReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace template'**
  String get storyEditorTemplateConflictReplace;

  /// No description provided for @storyEditorTemplateConflictReplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove untouched template blocks, keep your edited text, and add the new structure.'**
  String get storyEditorTemplateConflictReplaceDescription;

  /// No description provided for @storyEditorTemplateConflictAppend.
  ///
  /// In en, this message translates to:
  /// **'Add to current story'**
  String get storyEditorTemplateConflictAppend;

  /// No description provided for @storyEditorTemplateConflictAppendDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep everything and append the new structure below your current blocks.'**
  String get storyEditorTemplateConflictAppendDescription;

  /// No description provided for @storyEditorTemplateConflictMetadataOnly.
  ///
  /// In en, this message translates to:
  /// **'Update type and topic'**
  String get storyEditorTemplateConflictMetadataOnly;

  /// No description provided for @storyEditorTemplateConflictMetadataOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Change only the content type and topic without changing blocks.'**
  String get storyEditorTemplateConflictMetadataOnlyDescription;

  /// No description provided for @storyEditorFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Content type'**
  String get storyEditorFormatLabel;

  /// No description provided for @storyEditorPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get storyEditorPlaceLabel;

  /// No description provided for @storyEditorCountryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get storyEditorCountryCodeLabel;

  /// No description provided for @storyEditorCountryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'KZ'**
  String get storyEditorCountryCodeHint;

  /// No description provided for @storyEditorCityPlaceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'City/place id'**
  String get storyEditorCityPlaceIdLabel;

  /// No description provided for @storyEditorTagsHint.
  ///
  /// In en, this message translates to:
  /// **'mountains, food, weekend'**
  String get storyEditorTagsHint;

  /// No description provided for @storyEditorCoverSelected.
  ///
  /// In en, this message translates to:
  /// **'Cover selected'**
  String get storyEditorCoverSelected;

  /// No description provided for @storyEditorCoverRequired.
  ///
  /// In en, this message translates to:
  /// **'Cover required'**
  String get storyEditorCoverRequired;

  /// No description provided for @storyEditorReplaceCover.
  ///
  /// In en, this message translates to:
  /// **'Replace cover'**
  String get storyEditorReplaceCover;

  /// No description provided for @storyEditorAddCover.
  ///
  /// In en, this message translates to:
  /// **'Add cover'**
  String get storyEditorAddCover;

  /// No description provided for @storyEditorClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get storyEditorClear;

  /// No description provided for @storyEditorToolbarAddBlock.
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get storyEditorToolbarAddBlock;

  /// No description provided for @storyEditorToolbarHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get storyEditorToolbarHeading;

  /// No description provided for @storyEditorToolbarBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get storyEditorToolbarBold;

  /// No description provided for @storyEditorToolbarItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get storyEditorToolbarItalic;

  /// No description provided for @storyEditorToolbarStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get storyEditorToolbarStrikethrough;

  /// No description provided for @storyEditorToolbarUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get storyEditorToolbarUnderline;

  /// No description provided for @storyEditorToolbarList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get storyEditorToolbarList;

  /// No description provided for @storyEditorToolbarQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get storyEditorToolbarQuote;

  /// No description provided for @storyEditorToolbarImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get storyEditorToolbarImage;

  /// No description provided for @storyEditorToolbarUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get storyEditorToolbarUndo;

  /// No description provided for @storyEditorToolbarRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get storyEditorToolbarRedo;

  /// No description provided for @storyEditorAddBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get storyEditorAddBlockTitle;

  /// No description provided for @storyEditorBlockParagraph.
  ///
  /// In en, this message translates to:
  /// **'Paragraph'**
  String get storyEditorBlockParagraph;

  /// No description provided for @storyEditorBlockParagraphDescription.
  ///
  /// In en, this message translates to:
  /// **'Body text for the story'**
  String get storyEditorBlockParagraphDescription;

  /// No description provided for @storyEditorBlockHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get storyEditorBlockHeading;

  /// No description provided for @storyEditorBlockHeadingDescription.
  ///
  /// In en, this message translates to:
  /// **'Section title'**
  String get storyEditorBlockHeadingDescription;

  /// No description provided for @storyEditorBlockList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get storyEditorBlockList;

  /// No description provided for @storyEditorBlockListDescription.
  ///
  /// In en, this message translates to:
  /// **'Useful tips or steps'**
  String get storyEditorBlockListDescription;

  /// No description provided for @storyEditorBlockImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get storyEditorBlockImage;

  /// No description provided for @storyEditorBlockImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Single media upload'**
  String get storyEditorBlockImageDescription;

  /// No description provided for @storyEditorBlockGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get storyEditorBlockGallery;

  /// No description provided for @storyEditorBlockGalleryDescription.
  ///
  /// In en, this message translates to:
  /// **'Multiple images'**
  String get storyEditorBlockGalleryDescription;

  /// No description provided for @storyEditorBlockQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get storyEditorBlockQuote;

  /// No description provided for @storyEditorBlockQuoteDescription.
  ///
  /// In en, this message translates to:
  /// **'A highlighted sentence'**
  String get storyEditorBlockQuoteDescription;

  /// No description provided for @storyEditorBlockCallout.
  ///
  /// In en, this message translates to:
  /// **'Callout'**
  String get storyEditorBlockCallout;

  /// No description provided for @storyEditorBlockCalloutDescription.
  ///
  /// In en, this message translates to:
  /// **'Important travel note'**
  String get storyEditorBlockCalloutDescription;

  /// No description provided for @storyEditorBlockDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get storyEditorBlockDivider;

  /// No description provided for @storyEditorBlockDividerDescription.
  ///
  /// In en, this message translates to:
  /// **'Visual section break'**
  String get storyEditorBlockDividerDescription;

  /// No description provided for @storyEditorBlockPlaceReference.
  ///
  /// In en, this message translates to:
  /// **'Place reference'**
  String get storyEditorBlockPlaceReference;

  /// No description provided for @storyEditorBlockPlaceReferenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Link a place to the story'**
  String get storyEditorBlockPlaceReferenceDescription;

  /// No description provided for @storyEditorBlockRouteReference.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get storyEditorBlockRouteReference;

  /// No description provided for @storyEditorBlockRouteReferenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Share one of your routes in the post'**
  String get storyEditorBlockRouteReferenceDescription;

  /// No description provided for @storyEditorBlockNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get storyEditorBlockNumberedList;

  /// No description provided for @storyEditorStartWithBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a block'**
  String get storyEditorStartWithBlockTitle;

  /// No description provided for @storyEditorStartWithBlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add text, media, places, callouts, or dividers to shape the story.'**
  String get storyEditorStartWithBlockSubtitle;

  /// No description provided for @storyEditorPlaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get storyEditorPlaceNameHint;

  /// No description provided for @storyEditorRouteReferencePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get storyEditorRouteReferencePickerTitle;

  /// No description provided for @storyEditorRouteReferenceEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Publish or unlist a route first, then add it to a post.'**
  String get storyEditorRouteReferenceEmptyState;

  /// No description provided for @storyEditorRouteReferenceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your routes.'**
  String get storyEditorRouteReferenceLoadError;

  /// No description provided for @storyEditorRouteReferenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Route is not selected'**
  String get storyEditorRouteReferenceEmpty;

  /// No description provided for @storyEditorTextHintHeading.
  ///
  /// In en, this message translates to:
  /// **'Write a clear section heading'**
  String get storyEditorTextHintHeading;

  /// No description provided for @storyEditorTextHintBulletedList.
  ///
  /// In en, this message translates to:
  /// **'Add list items, one per line'**
  String get storyEditorTextHintBulletedList;

  /// No description provided for @storyEditorTextHintNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Add ordered steps, one per line'**
  String get storyEditorTextHintNumberedList;

  /// No description provided for @storyEditorTextHintQuote.
  ///
  /// In en, this message translates to:
  /// **'Add a quote or memorable line'**
  String get storyEditorTextHintQuote;

  /// No description provided for @storyEditorTextHintCallout.
  ///
  /// In en, this message translates to:
  /// **'Highlight a practical tip'**
  String get storyEditorTextHintCallout;

  /// No description provided for @storyEditorTextHintParagraph.
  ///
  /// In en, this message translates to:
  /// **'Write your story'**
  String get storyEditorTextHintParagraph;

  /// No description provided for @storyEditorDeleteBlockSemantic.
  ///
  /// In en, this message translates to:
  /// **'Delete {block} block'**
  String storyEditorDeleteBlockSemantic(Object block);

  /// No description provided for @storyEditorReorderBlockSemantic.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder {block} block'**
  String storyEditorReorderBlockSemantic(Object block);

  /// No description provided for @storyEditorPublishReadiness.
  ///
  /// In en, this message translates to:
  /// **'Publish readiness'**
  String get storyEditorPublishReadiness;

  /// No description provided for @storyEditorChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get storyEditorChecklistTitle;

  /// No description provided for @storyEditorChecklistFormat.
  ///
  /// In en, this message translates to:
  /// **'Content type'**
  String get storyEditorChecklistFormat;

  /// No description provided for @storyEditorChecklistCategory.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get storyEditorChecklistCategory;

  /// No description provided for @storyEditorChecklistCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get storyEditorChecklistCover;

  /// No description provided for @storyEditorChecklistPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get storyEditorChecklistPlace;

  /// No description provided for @storyEditorChecklistCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get storyEditorChecklistCountry;

  /// No description provided for @storyEditorChecklistContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get storyEditorChecklistContent;

  /// No description provided for @storyEditorChecklistMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get storyEditorChecklistMedia;

  /// No description provided for @storyEditorChecklistReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get storyEditorChecklistReady;

  /// No description provided for @storyEditorChecklistNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get storyEditorChecklistNeedsAttention;

  /// No description provided for @storyEditorChecklistOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get storyEditorChecklistOpen;

  /// No description provided for @storyEditorConflictFallback.
  ///
  /// In en, this message translates to:
  /// **'Story was changed elsewhere.'**
  String get storyEditorConflictFallback;

  /// No description provided for @storyEditorSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get storyEditorSaveDraft;

  /// No description provided for @storyEditorPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get storyEditorPublish;

  /// No description provided for @storyEditorPublishSemantic.
  ///
  /// In en, this message translates to:
  /// **'Publish story'**
  String get storyEditorPublishSemantic;

  /// No description provided for @storyEditorAutosaveIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get storyEditorAutosaveIdle;

  /// No description provided for @storyEditorAutosaveSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get storyEditorAutosaveSaving;

  /// No description provided for @storyEditorAutosaveSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get storyEditorAutosaveSaved;

  /// No description provided for @storyEditorAutosaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get storyEditorAutosaveFailed;

  /// No description provided for @storyEditorAutosaveConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get storyEditorAutosaveConflict;

  /// No description provided for @storyEditorPublishNotReady.
  ///
  /// In en, this message translates to:
  /// **'Story is not ready to publish.'**
  String get storyEditorPublishNotReady;

  /// No description provided for @storyEditorMediaRetrySemantic.
  ///
  /// In en, this message translates to:
  /// **'Retry media upload'**
  String get storyEditorMediaRetrySemantic;

  /// No description provided for @storyEditorMediaRemoveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove media upload'**
  String get storyEditorMediaRemoveSemantic;

  /// No description provided for @storyEditorMediaRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get storyEditorMediaRetry;

  /// No description provided for @storyEditorMediaRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get storyEditorMediaRemove;

  /// No description provided for @storyEditorMediaQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued for upload'**
  String get storyEditorMediaQueued;

  /// No description provided for @storyEditorMediaUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get storyEditorMediaUploading;

  /// No description provided for @storyEditorMediaFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get storyEditorMediaFailed;

  /// No description provided for @storyEditorMediaComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload complete'**
  String get storyEditorMediaComplete;

  /// No description provided for @storyEditorMediaRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get storyEditorMediaRemoved;

  /// No description provided for @storyEditorMediaLocalPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Local preview unavailable. Remove and add this media again.'**
  String get storyEditorMediaLocalPreviewUnavailable;

  /// No description provided for @storyEditorMediaErrorRetryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry the media upload.'**
  String get storyEditorMediaErrorRetryUpload;

  /// No description provided for @storyEditorMediaErrorInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Upload was interrupted. Retry to continue.'**
  String get storyEditorMediaErrorInterrupted;

  /// No description provided for @storyEditorMediaErrorMissingSource.
  ///
  /// In en, this message translates to:
  /// **'Local media source is unavailable. Remove and add this media again.'**
  String get storyEditorMediaErrorMissingSource;

  /// No description provided for @storyEditorMediaErrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Media upload failed. Please try again.'**
  String get storyEditorMediaErrorUploadFailed;

  /// No description provided for @storyEditorImagePickTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Choose an image up to 20 MB.'**
  String get storyEditorImagePickTooLarge;

  /// No description provided for @storyEditorImagePickUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG, or WebP image.'**
  String get storyEditorImagePickUnsupported;

  /// No description provided for @storyEditorImagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this image. Please try another one.'**
  String get storyEditorImagePickFailed;

  /// No description provided for @storyEditorValidationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Story title is required.'**
  String get storyEditorValidationTitleRequired;

  /// No description provided for @storyEditorValidationFormatRequired.
  ///
  /// In en, this message translates to:
  /// **'Story format is required.'**
  String get storyEditorValidationFormatRequired;

  /// No description provided for @storyEditorValidationCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Story category is required.'**
  String get storyEditorValidationCategoryRequired;

  /// No description provided for @storyEditorValidationCoverRequired.
  ///
  /// In en, this message translates to:
  /// **'Story cover is required.'**
  String get storyEditorValidationCoverRequired;

  /// No description provided for @storyEditorValidationPlaceRequired.
  ///
  /// In en, this message translates to:
  /// **'Story place is required.'**
  String get storyEditorValidationPlaceRequired;

  /// No description provided for @storyEditorValidationCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Story country is required.'**
  String get storyEditorValidationCountryRequired;

  /// No description provided for @storyEditorValidationDraftRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title or at least one story block to save a draft.'**
  String get storyEditorValidationDraftRequired;

  /// No description provided for @storyEditorValidationContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Write at least one story block before publishing.'**
  String get storyEditorValidationContentRequired;

  /// No description provided for @storyEditorValidationMediaPending.
  ///
  /// In en, this message translates to:
  /// **'Wait until media uploads finish.'**
  String get storyEditorValidationMediaPending;

  /// No description provided for @postCreateRateLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Post limit'**
  String get postCreateRateLimitTitle;

  /// No description provided for @postCreateRateLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You have created the maximum number of posts in the last hour. You can create another post in about {minutes} min.'**
  String postCreateRateLimitMessage(int minutes);

  /// No description provided for @postCreateRateLimitAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get postCreateRateLimitAction;

  /// No description provided for @postCreatePreflightFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check the post limit. We will check again when you publish.'**
  String get postCreatePreflightFailed;

  /// No description provided for @chatListTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatListTitle;

  /// No description provided for @chatListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats'**
  String get chatListLoadFailed;

  /// No description provided for @chatListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatListEmpty;

  /// No description provided for @chatListPersonalTab.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get chatListPersonalTab;

  /// No description provided for @chatListActivitiesTab.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get chatListActivitiesTab;

  /// No description provided for @chatListExcursionsTab.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get chatListExcursionsTab;

  /// No description provided for @chatListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatListSearchHint;

  /// No description provided for @chatListSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats found'**
  String get chatListSearchEmpty;

  /// No description provided for @chatMuteNotificationsAction.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get chatMuteNotificationsAction;

  /// No description provided for @chatUnmuteNotificationsAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get chatUnmuteNotificationsAction;

  /// No description provided for @chatMuteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update chat notifications'**
  String get chatMuteUpdateFailed;

  /// No description provided for @chatBlockUserAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlockUserAction;

  /// No description provided for @chatUnblockUserAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get chatUnblockUserAction;

  /// No description provided for @chatUserBlockUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user block status'**
  String get chatUserBlockUpdateFailed;

  /// No description provided for @chatFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatFallbackTitle;

  /// No description provided for @chatGroupFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Chat'**
  String get chatGroupFallbackTitle;

  /// No description provided for @chatActivityFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity chat'**
  String get chatActivityFallbackTitle;

  /// No description provided for @chatActiveNow.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE NOW'**
  String get chatActiveNow;

  /// No description provided for @chatPresenceOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get chatPresenceOnline;

  /// No description provided for @chatPresenceOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get chatPresenceOffline;

  /// No description provided for @chatPresenceLastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'last seen just now'**
  String get chatPresenceLastSeenJustNow;

  /// No description provided for @chatPresenceLastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last seen 1 minute ago} other{last seen {count} minutes ago}}'**
  String chatPresenceLastSeenMinutes(num count);

  /// No description provided for @chatPresenceLastSeenHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last seen 1 hour ago} other{last seen {count} hours ago}}'**
  String chatPresenceLastSeenHours(num count);

  /// No description provided for @chatPresenceLastSeenDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last seen 1 day ago} other{last seen {count} days ago}}'**
  String chatPresenceLastSeenDays(num count);

  /// No description provided for @chatParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No participants} =1{1 participant} other{{count} participants}}'**
  String chatParticipantsCount(num count);

  /// No description provided for @chatPinnedMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'PINNED MESSAGE'**
  String get chatPinnedMessageLabel;

  /// No description provided for @chatPinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get chatPinAction;

  /// No description provided for @chatUnpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatUnpinAction;

  /// No description provided for @chatPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pin the message. Please try again.'**
  String get chatPinFailed;

  /// No description provided for @chatUnpinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unpin the message. Please try again.'**
  String get chatUnpinFailed;

  /// No description provided for @chatDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDateToday;

  /// No description provided for @chatDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatDateYesterday;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get chatMessageDeleted;

  /// No description provided for @chatMessageRemovedByModerator.
  ///
  /// In en, this message translates to:
  /// **'Message removed by moderator'**
  String get chatMessageRemovedByModerator;

  /// No description provided for @chatModeratorComment.
  ///
  /// In en, this message translates to:
  /// **'Moderator comment: {comment}'**
  String chatModeratorComment(Object comment);

  /// No description provided for @chatDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDeleteAction;

  /// No description provided for @chatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the message. Please try again.'**
  String get chatDeleteFailed;

  /// No description provided for @chatEditedLabel.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get chatEditedLabel;

  /// No description provided for @chatUserFallbackName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get chatUserFallbackName;

  /// No description provided for @chatReplyPreviewFallback.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatReplyPreviewFallback;

  /// No description provided for @chatSystemUserJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String chatSystemUserJoined(Object name);

  /// No description provided for @chatSystemUserLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String chatSystemUserLeft(Object name);

  /// No description provided for @chatSystemUpdate.
  ///
  /// In en, this message translates to:
  /// **'System update'**
  String get chatSystemUpdate;

  /// No description provided for @chatAttachmentPhotoVideo.
  ///
  /// In en, this message translates to:
  /// **'Photo / Video'**
  String get chatAttachmentPhotoVideo;

  /// No description provided for @chatAttachmentFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatAttachmentFile;

  /// No description provided for @chatLastMessagePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatLastMessagePhoto;

  /// No description provided for @chatLastMessageVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatLastMessageVideo;

  /// No description provided for @chatAttachmentLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatAttachmentLocation;

  /// No description provided for @chatAttachmentAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get chatAttachmentAudio;

  /// No description provided for @chatAttachmentTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get chatAttachmentTakePhoto;

  /// No description provided for @chatAttachmentTakeVideo.
  ///
  /// In en, this message translates to:
  /// **'Take video'**
  String get chatAttachmentTakeVideo;

  /// No description provided for @chatAttachmentChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chatAttachmentChooseFromGallery;

  /// No description provided for @chatAttachmentCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatAttachmentCameraTitle;

  /// No description provided for @chatAttachmentAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get chatAttachmentAttachTitle;

  /// No description provided for @chatAttachmentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chatAttachmentCancel;

  /// No description provided for @chatAttachmentVideoTooLong.
  ///
  /// In en, this message translates to:
  /// **'Video is too long. Use a clip up to 5 minutes.'**
  String get chatAttachmentVideoTooLong;

  /// No description provided for @chatComposerCameraButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatComposerCameraButtonLabel;

  /// No description provided for @chatComposerAttachButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get chatComposerAttachButtonLabel;

  /// No description provided for @chatComposerEmojiButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Emoji and stickers'**
  String get chatComposerEmojiButtonLabel;

  /// No description provided for @chatComposerEmojiTab.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatComposerEmojiTab;

  /// No description provided for @chatComposerStickerTab.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get chatComposerStickerTab;

  /// No description provided for @chatStickerMessage.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get chatStickerMessage;

  /// No description provided for @chatStickerCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get chatStickerCreateAction;

  /// No description provided for @chatStickerCreated.
  ///
  /// In en, this message translates to:
  /// **'Sticker added'**
  String get chatStickerCreated;

  /// No description provided for @chatStickerCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the sticker. Please try again.'**
  String get chatStickerCreateFailed;

  /// No description provided for @chatStickerSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the sticker. Please try again.'**
  String get chatStickerSendFailed;

  /// No description provided for @chatStickerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your stickers.'**
  String get chatStickerLoadFailed;

  /// No description provided for @chatComposerPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get chatComposerPaste;

  /// No description provided for @chatComposerPasteImage.
  ///
  /// In en, this message translates to:
  /// **'Paste image'**
  String get chatComposerPasteImage;

  /// No description provided for @chatClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to paste'**
  String get chatClipboardEmpty;

  /// No description provided for @chatPasteImagePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Send pasted image'**
  String get chatPasteImagePreviewTitle;

  /// No description provided for @chatPasteSendImage.
  ///
  /// In en, this message translates to:
  /// **'Send image'**
  String get chatPasteSendImage;

  /// No description provided for @chatPasteSendSticker.
  ///
  /// In en, this message translates to:
  /// **'Add as sticker'**
  String get chatPasteSendSticker;

  /// No description provided for @stickersTabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get stickersTabRecent;

  /// No description provided for @stickersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get stickersSearchHint;

  /// No description provided for @stickersEmptyRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent stickers yet'**
  String get stickersEmptyRecent;

  /// No description provided for @stickersEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No stickers found'**
  String get stickersEmptySearch;

  /// No description provided for @stickersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load stickers'**
  String get stickersLoadFailed;

  /// No description provided for @stickersRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get stickersRetry;

  /// No description provided for @stickersOpenPicker.
  ///
  /// In en, this message translates to:
  /// **'Open stickers'**
  String get stickersOpenPicker;

  /// No description provided for @chatStickerUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Use a JPG, PNG, or WebP image for stickers.'**
  String get chatStickerUnsupported;

  /// No description provided for @chatStickerTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Sticker image is too large. Use an image up to 5 MB.'**
  String get chatStickerTooLarge;

  /// No description provided for @chatCameraPhotoMode.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatCameraPhotoMode;

  /// No description provided for @chatCameraVideoMode.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatCameraVideoMode;

  /// No description provided for @chatCameraRecording.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get chatCameraRecording;

  /// No description provided for @chatCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone access are required to capture chat media.'**
  String get chatCameraPermissionDenied;

  /// No description provided for @chatCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable on this device.'**
  String get chatCameraUnavailable;

  /// No description provided for @chatCameraCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not capture media. Please try again.'**
  String get chatCameraCaptureFailed;

  /// No description provided for @chatCameraFlipButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get chatCameraFlipButtonLabel;

  /// No description provided for @chatCameraFlashOffButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get chatCameraFlashOffButtonLabel;

  /// No description provided for @chatCameraFlashAutoButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto flash'**
  String get chatCameraFlashAutoButtonLabel;

  /// No description provided for @chatCameraFlashOnButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get chatCameraFlashOnButtonLabel;

  /// No description provided for @chatCameraCloseButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Close camera'**
  String get chatCameraCloseButtonLabel;

  /// No description provided for @chatCameraCapturePhotoButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get chatCameraCapturePhotoButtonLabel;

  /// No description provided for @chatCameraRecordVideoButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get chatCameraRecordVideoButtonLabel;

  /// No description provided for @chatCameraStopRecordingButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get chatCameraStopRecordingButtonLabel;

  /// No description provided for @chatCameraReviewCancelButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chatCameraReviewCancelButtonLabel;

  /// No description provided for @chatCameraReviewSendButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatCameraReviewSendButtonLabel;

  /// No description provided for @chatCameraReviewPlayButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get chatCameraReviewPlayButtonLabel;

  /// No description provided for @chatCameraReviewPauseButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause video'**
  String get chatCameraReviewPauseButtonLabel;

  /// No description provided for @chatCameraReviewTrimLabel.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get chatCameraReviewTrimLabel;

  /// No description provided for @chatCameraReviewProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get chatCameraReviewProcessing;

  /// No description provided for @chatCameraTrimFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not trim this video. Try a different trim range or send the original.'**
  String get chatCameraTrimFailed;

  /// No description provided for @chatAttachmentUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading attachment...'**
  String get chatAttachmentUploading;

  /// No description provided for @chatAttachmentDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get chatAttachmentDownloading;

  /// No description provided for @chatAttachmentDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded. Tap again to open.'**
  String get chatAttachmentDownloaded;

  /// No description provided for @chatAttachmentDownloadedStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get chatAttachmentDownloadedStatus;

  /// No description provided for @chatAttachmentNotDownloadedStatus.
  ///
  /// In en, this message translates to:
  /// **'Tap to download'**
  String get chatAttachmentNotDownloadedStatus;

  /// No description provided for @chatAttachmentDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the file. Please try again.'**
  String get chatAttachmentDownloadFailed;

  /// No description provided for @chatAttachmentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this file on the device.'**
  String get chatAttachmentOpenFailed;

  /// No description provided for @chatAttachmentUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload the attachment. Please try again.'**
  String get chatAttachmentUploadFailed;

  /// No description provided for @chatAttachmentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported for chat attachments.'**
  String get chatAttachmentUnsupported;

  /// No description provided for @chatAttachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The attachment is too large. Use a file up to 25 MB.'**
  String get chatAttachmentTooLarge;

  /// No description provided for @chatComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get chatComposerHint;

  /// No description provided for @chatComposerClosedHint.
  ///
  /// In en, this message translates to:
  /// **'Chat is closed'**
  String get chatComposerClosedHint;

  /// No description provided for @chatActivityChatClosed.
  ///
  /// In en, this message translates to:
  /// **'This chat is now read-only.'**
  String get chatActivityChatClosed;

  /// No description provided for @chatActivityChatClosedHistoryNotice.
  ///
  /// In en, this message translates to:
  /// **'The event has ended. Messages can no longer be sent in this chat.'**
  String get chatActivityChatClosedHistoryNotice;

  /// No description provided for @chatVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceMessage;

  /// No description provided for @chatVoiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording voice message'**
  String get chatVoiceRecording;

  /// No description provided for @chatVoiceRecordingLocked.
  ///
  /// In en, this message translates to:
  /// **'Recording locked'**
  String get chatVoiceRecordingLocked;

  /// No description provided for @chatVoicePreparingPreview.
  ///
  /// In en, this message translates to:
  /// **'Preparing voice preview...'**
  String get chatVoicePreparingPreview;

  /// No description provided for @chatVoicePreview.
  ///
  /// In en, this message translates to:
  /// **'Voice preview'**
  String get chatVoicePreview;

  /// No description provided for @chatVoiceSlideUpToLock.
  ///
  /// In en, this message translates to:
  /// **'Slide up to lock recording'**
  String get chatVoiceSlideUpToLock;

  /// No description provided for @chatVoiceRecordPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required to record voice messages.'**
  String get chatVoiceRecordPermissionDenied;

  /// No description provided for @chatVoiceRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record the voice message. Please try again.'**
  String get chatVoiceRecordFailed;

  /// No description provided for @chatVoicePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play this voice message.'**
  String get chatVoicePlaybackFailed;

  /// No description provided for @chatVoiceTooShort.
  ///
  /// In en, this message translates to:
  /// **'Voice message is too short.'**
  String get chatVoiceTooShort;

  /// No description provided for @chatReactionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get chatReactionSheetTitle;

  /// No description provided for @chatReactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the reaction. Please try again.'**
  String get chatReactionFailed;

  /// No description provided for @chatCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopyAction;

  /// No description provided for @chatForwardAction.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForwardAction;

  /// No description provided for @chatMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get chatMessageCopied;

  /// No description provided for @chatForwardSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forward to'**
  String get chatForwardSheetTitle;

  /// No description provided for @chatForwardFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not forward the message. Please try again.'**
  String get chatForwardFailed;

  /// No description provided for @chatForwardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message forwarded'**
  String get chatForwardSuccess;

  /// No description provided for @chatNoForwardTargets.
  ///
  /// In en, this message translates to:
  /// **'No available chats'**
  String get chatNoForwardTargets;

  /// No description provided for @chatForwardedLabel.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get chatForwardedLabel;

  /// No description provided for @chatStoryReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply to story'**
  String get chatStoryReplyLabel;

  /// No description provided for @chatStoryReplyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Story is no longer available'**
  String get chatStoryReplyUnavailable;

  /// No description provided for @chatForwardedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forwarded from {name}'**
  String chatForwardedFrom(Object name);

  /// No description provided for @chatForwardCount.
  ///
  /// In en, this message translates to:
  /// **'Forwarded {count}'**
  String chatForwardCount(Object count);

  /// No description provided for @chatReactionsByTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get chatReactionsByTitle;

  /// No description provided for @chatReactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reaction} other{{count} reactions}}'**
  String chatReactionCount(num count);

  /// No description provided for @chatReadByTitle.
  ///
  /// In en, this message translates to:
  /// **'Read by'**
  String get chatReadByTitle;

  /// No description provided for @chatReadByCount.
  ///
  /// In en, this message translates to:
  /// **'Read by {count}'**
  String chatReadByCount(Object count);

  /// No description provided for @chatReadAtSeparator.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get chatReadAtSeparator;

  /// No description provided for @chatNoStatusDetails.
  ///
  /// In en, this message translates to:
  /// **'No status details yet'**
  String get chatNoStatusDetails;

  /// No description provided for @chatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat'**
  String get chatLoadFailed;

  /// No description provided for @chatParticipantsHostSection.
  ///
  /// In en, this message translates to:
  /// **'HOST & ORGANIZER'**
  String get chatParticipantsHostSection;

  /// No description provided for @chatParticipantsJoinedSection.
  ///
  /// In en, this message translates to:
  /// **'JOINED PARTICIPANTS'**
  String get chatParticipantsJoinedSection;

  /// No description provided for @chatParticipantHostStatus.
  ///
  /// In en, this message translates to:
  /// **'host & organizer'**
  String get chatParticipantHostStatus;

  /// No description provided for @chatParticipantYouStatus.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get chatParticipantYouStatus;

  /// No description provided for @chatParticipantJoinedStatus.
  ///
  /// In en, this message translates to:
  /// **'joined participant'**
  String get chatParticipantJoinedStatus;

  /// No description provided for @chatParticipantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other participants yet'**
  String get chatParticipantsEmpty;

  /// No description provided for @chatSharedMediaTab.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get chatSharedMediaTab;

  /// No description provided for @chatSharedLinksTab.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get chatSharedLinksTab;

  /// No description provided for @chatSharedFilesTab.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get chatSharedFilesTab;

  /// No description provided for @chatSharedVoiceTab.
  ///
  /// In en, this message translates to:
  /// **'Audio messages'**
  String get chatSharedVoiceTab;

  /// No description provided for @chatSharedNoMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'No media yet'**
  String get chatSharedNoMediaTitle;

  /// No description provided for @chatSharedNoMediaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos from this chat will appear here.'**
  String get chatSharedNoMediaSubtitle;

  /// No description provided for @chatSharedNoLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'No links yet'**
  String get chatSharedNoLinksTitle;

  /// No description provided for @chatSharedNoLinksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages with links will be collected here.'**
  String get chatSharedNoLinksSubtitle;

  /// No description provided for @chatSharedNoFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get chatSharedNoFilesTitle;

  /// No description provided for @chatSharedNoFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Documents and archives from this chat will appear here.'**
  String get chatSharedNoFilesSubtitle;

  /// No description provided for @chatSharedNoVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'No voice messages yet'**
  String get chatSharedNoVoiceTitle;

  /// No description provided for @chatSharedNoVoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice messages from this chat will appear here.'**
  String get chatSharedNoVoiceSubtitle;

  /// No description provided for @chatSharedFileFallback.
  ///
  /// In en, this message translates to:
  /// **'File {id}'**
  String chatSharedFileFallback(Object id);

  /// No description provided for @chatSharedUnknownFile.
  ///
  /// In en, this message translates to:
  /// **'Unknown file'**
  String get chatSharedUnknownFile;

  /// No description provided for @chatSharedGoToMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Go to message'**
  String get chatSharedGoToMessageAction;

  /// No description provided for @chatExternalLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Open external link?'**
  String get chatExternalLinkTitle;

  /// No description provided for @chatExternalLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'This link opens a third-party resource:\n{url}'**
  String chatExternalLinkMessage(Object url);

  /// No description provided for @chatExternalLinkOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get chatExternalLinkOpenAction;

  /// No description provided for @chatExternalLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get chatExternalLinkOpenFailed;

  /// No description provided for @chatSharedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load content'**
  String get chatSharedLoadFailed;

  /// No description provided for @chatSharedLoadFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check the connection and retry.'**
  String get chatSharedLoadFailedSubtitle;

  /// No description provided for @chatSharedPartialLoadWarning.
  ///
  /// In en, this message translates to:
  /// **'Some older shared items could not be loaded.'**
  String get chatSharedPartialLoadWarning;

  /// No description provided for @guideCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide calendar'**
  String get guideCalendarTitle;

  /// No description provided for @guideCalendarAddSlot.
  ///
  /// In en, this message translates to:
  /// **'Slot'**
  String get guideCalendarAddSlot;

  /// No description provided for @guideCalendarEditSlot.
  ///
  /// In en, this message translates to:
  /// **'Edit slot'**
  String get guideCalendarEditSlot;

  /// No description provided for @guideCalendarEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No slots for this day'**
  String get guideCalendarEmptyDay;

  /// No description provided for @guideCalendarAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get guideCalendarAvailable;

  /// No description provided for @guideCalendarBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get guideCalendarBooked;

  /// No description provided for @guideCalendarClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get guideCalendarClosed;

  /// No description provided for @guideCalendarCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get guideCalendarCancelled;

  /// No description provided for @guideCalendarCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get guideCalendarCompleted;

  /// No description provided for @guideCalendarViewSlot.
  ///
  /// In en, this message translates to:
  /// **'Slot details'**
  String get guideCalendarViewSlot;

  /// No description provided for @guideCalendarReadonlyCompletedSlot.
  ///
  /// In en, this message translates to:
  /// **'This slot has already finished. It is kept in the calendar for history and can only be viewed.'**
  String get guideCalendarReadonlyCompletedSlot;

  /// No description provided for @guideCalendarCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String guideCalendarCancelReason(Object reason);

  /// No description provided for @guideCalendarAutoCancelNoBookings.
  ///
  /// In en, this message translates to:
  /// **'no one booked this slot at least 2 hours before start'**
  String get guideCalendarAutoCancelNoBookings;

  /// No description provided for @guideCalendarRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Repeat weekly'**
  String get guideCalendarRepeatWeekly;

  /// No description provided for @guideCalendarConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'This time overlaps another excursion'**
  String get guideCalendarConflictTitle;

  /// No description provided for @guideCalendarSuggestNextTime.
  ///
  /// In en, this message translates to:
  /// **'Choose the next available time'**
  String get guideCalendarSuggestNextTime;

  /// No description provided for @guideCalendarDeleteSlot.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get guideCalendarDeleteSlot;

  /// No description provided for @guideCalendarCancelSlot.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get guideCalendarCancelSlot;

  /// No description provided for @guideCalendarCloseSlot.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get guideCalendarCloseSlot;

  /// No description provided for @guideCalendarOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Published offer'**
  String get guideCalendarOfferLabel;

  /// No description provided for @guideCalendarNoPublishedOffers.
  ///
  /// In en, this message translates to:
  /// **'Publish an excursion offer first to add it to the schedule.'**
  String get guideCalendarNoPublishedOffers;

  /// No description provided for @guideCalendarOfferRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose an excursion offer'**
  String get guideCalendarOfferRequired;

  /// No description provided for @guideCalendarCurrentOfferFallback.
  ///
  /// In en, this message translates to:
  /// **'Current offer'**
  String get guideCalendarCurrentOfferFallback;

  /// No description provided for @guideCalendarOfferDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String guideCalendarOfferDuration(Object minutes);

  /// No description provided for @guideCalendarOfferCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} seats'**
  String guideCalendarOfferCapacity(Object count);

  /// No description provided for @guideCalendarDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get guideCalendarDateLabel;

  /// No description provided for @guideCalendarDateHint.
  ///
  /// In en, this message translates to:
  /// **'dd.mm.yyyy'**
  String get guideCalendarDateHint;

  /// No description provided for @guideCalendarInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter the date as dd.mm.yyyy'**
  String get guideCalendarInvalidDate;

  /// No description provided for @guideCalendarTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get guideCalendarTimeLabel;

  /// No description provided for @guideCalendarTimeHint.
  ///
  /// In en, this message translates to:
  /// **'hh:mm'**
  String get guideCalendarTimeHint;

  /// No description provided for @guideCalendarInvalidTime.
  ///
  /// In en, this message translates to:
  /// **'Enter the time as hh:mm'**
  String get guideCalendarInvalidTime;

  /// No description provided for @guideCalendarCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get guideCalendarCapacityLabel;

  /// No description provided for @guideCalendarCapacityMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum for this offer: {count}'**
  String guideCalendarCapacityMax(Object count);

  /// No description provided for @guideCalendarCapacityTooHigh.
  ///
  /// In en, this message translates to:
  /// **'This offer allows up to {count} seats'**
  String guideCalendarCapacityTooHigh(Object count);

  /// No description provided for @guideCalendarSlotLeadTimeTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and time at least 3 hours before the start.'**
  String get guideCalendarSlotLeadTimeTooSoon;

  /// No description provided for @guideCalendarSaveSlot.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get guideCalendarSaveSlot;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important updates for trips, activities, and excursions'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsCategoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All quiet for now'**
  String get notificationsCategoriesEmptyTitle;

  /// No description provided for @notificationsCategoriesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The latest updates for your categories will appear here.'**
  String get notificationsCategoriesEmptySubtitle;

  /// No description provided for @notificationsLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get notificationsLoadFailedTitle;

  /// No description provided for @notificationsLoadFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get notificationsLoadFailedSubtitle;

  /// No description provided for @notificationsCategoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications in this category yet'**
  String get notificationsCategoryEmptyTitle;

  /// No description provided for @notificationsCategoryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'New events will appear here automatically.'**
  String get notificationsCategoryEmptySubtitle;

  /// No description provided for @notificationsReadAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsReadAll;

  /// No description provided for @notificationsReadAllDone.
  ///
  /// In en, this message translates to:
  /// **'All notifications in this category are read'**
  String get notificationsReadAllDone;

  /// No description provided for @notificationsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String notificationsUnreadCount(Object count);

  /// No description provided for @notificationsCategoryActivity.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get notificationsCategoryActivity;

  /// No description provided for @notificationsCategoryExcursion.
  ///
  /// In en, this message translates to:
  /// **'Excursions'**
  String get notificationsCategoryExcursion;

  /// No description provided for @notificationsCategoryBooking.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get notificationsCategoryBooking;

  /// No description provided for @notificationsCategoryChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get notificationsCategoryChecklist;

  /// No description provided for @notificationsCategoryChat.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationsCategoryChat;

  /// No description provided for @notificationsCategoryContent.
  ///
  /// In en, this message translates to:
  /// **'Posts and stories'**
  String get notificationsCategoryContent;

  /// No description provided for @notificationsCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationsCategorySystem;

  /// No description provided for @notificationsCategorySupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get notificationsCategorySupport;

  /// No description provided for @notificationsCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notificationsCategoryGeneral;

  /// No description provided for @notificationsCategoryFallback.
  ///
  /// In en, this message translates to:
  /// **'Category {category}'**
  String notificationsCategoryFallback(Object category);

  /// No description provided for @notificationsSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get notificationsSomeone;

  /// No description provided for @notificationsPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get notificationsPriorityHigh;

  /// No description provided for @notificationsStoryLikeTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} liked your story'**
  String notificationsStoryLikeTitle(Object actor);

  /// No description provided for @notificationsStoryLikeBody.
  ///
  /// In en, this message translates to:
  /// **'Open the story to see the reaction.'**
  String get notificationsStoryLikeBody;

  /// No description provided for @notificationsStoryReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} replied to your story'**
  String notificationsStoryReplyTitle(Object actor);

  /// No description provided for @notificationsStoryReplyBody.
  ///
  /// In en, this message translates to:
  /// **'The reply was sent to your chat.'**
  String get notificationsStoryReplyBody;

  /// No description provided for @notificationsPostLikeTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} liked your post'**
  String notificationsPostLikeTitle(Object actor);

  /// No description provided for @notificationsPostLikeBody.
  ///
  /// In en, this message translates to:
  /// **'Open the post to see the reaction.'**
  String get notificationsPostLikeBody;

  /// No description provided for @notificationsPostCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} commented on your post'**
  String notificationsPostCommentTitle(Object actor);

  /// No description provided for @notificationsPostCommentBody.
  ///
  /// In en, this message translates to:
  /// **'Open the post to continue the discussion.'**
  String get notificationsPostCommentBody;

  /// No description provided for @notificationsChatMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New message from {actor}'**
  String notificationsChatMessageTitle(Object actor);

  /// No description provided for @notificationsChatMessageBody.
  ///
  /// In en, this message translates to:
  /// **'Open chats to reply.'**
  String get notificationsChatMessageBody;

  /// No description provided for @notificationsSupportRepliedTitle.
  ///
  /// In en, this message translates to:
  /// **'Support replied'**
  String get notificationsSupportRepliedTitle;

  /// No description provided for @notificationsSupportRepliedBody.
  ///
  /// In en, this message translates to:
  /// **'Support replied to your ticket.'**
  String get notificationsSupportRepliedBody;

  /// No description provided for @notificationsSupportUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Support request updated'**
  String get notificationsSupportUpdatedTitle;

  /// No description provided for @notificationsSupportUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Open support chat to see the latest update.'**
  String get notificationsSupportUpdatedBody;

  /// No description provided for @notificationsActivityJoinedTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} joined your activity'**
  String notificationsActivityJoinedTitle(Object actor);

  /// No description provided for @notificationsActivityJoinedBody.
  ///
  /// In en, this message translates to:
  /// **'Open the activity to see participants.'**
  String get notificationsActivityJoinedBody;

  /// No description provided for @notificationsActivityParticipantWaitlistedTitle.
  ///
  /// In en, this message translates to:
  /// **'Participant joined the waitlist'**
  String get notificationsActivityParticipantWaitlistedTitle;

  /// No description provided for @notificationsActivityParticipantWaitlistedBody.
  ///
  /// In en, this message translates to:
  /// **'Open the activity to manage the waitlist.'**
  String get notificationsActivityParticipantWaitlistedBody;

  /// No description provided for @notificationsActivityParticipantLeftTitle.
  ///
  /// In en, this message translates to:
  /// **'Participant left the activity'**
  String get notificationsActivityParticipantLeftTitle;

  /// No description provided for @notificationsActivityParticipantLeftBody.
  ///
  /// In en, this message translates to:
  /// **'Open the activity to check the current participant list.'**
  String get notificationsActivityParticipantLeftBody;

  /// No description provided for @notificationsActivityLateCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'Late cancellation'**
  String get notificationsActivityLateCancellationTitle;

  /// No description provided for @notificationsActivityLateCancellationBody.
  ///
  /// In en, this message translates to:
  /// **'A participant cancelled close to the start time.'**
  String get notificationsActivityLateCancellationBody;

  /// No description provided for @notificationsActivityCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity cancelled'**
  String get notificationsActivityCancelledTitle;

  /// No description provided for @notificationsActivityCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'Activity \"{activity}\" was cancelled.'**
  String notificationsActivityCancelledBody(Object activity);

  /// No description provided for @notificationsActivityCancelledBodyGeneric.
  ///
  /// In en, this message translates to:
  /// **'This activity was cancelled.'**
  String get notificationsActivityCancelledBodyGeneric;

  /// No description provided for @notificationsActivityConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity confirmed'**
  String get notificationsActivityConfirmedTitle;

  /// No description provided for @notificationsActivityConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Open the activity to see the latest details.'**
  String get notificationsActivityConfirmedBody;

  /// No description provided for @notificationsActivityCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity completed'**
  String get notificationsActivityCompletedTitle;

  /// No description provided for @notificationsActivityCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'You can now review your experience.'**
  String get notificationsActivityCompletedBody;

  /// No description provided for @notificationsExcursionBookingCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'New excursion booking'**
  String get notificationsExcursionBookingCreatedTitle;

  /// No description provided for @notificationsExcursionBookingCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'Open the guide dashboard to see booking details.'**
  String get notificationsExcursionBookingCreatedBody;

  /// No description provided for @notificationsExcursionBookingCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion booking cancelled'**
  String get notificationsExcursionBookingCancelledTitle;

  /// No description provided for @notificationsExcursionBookingCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'A traveler cancelled this excursion.'**
  String get notificationsExcursionBookingCancelledBody;

  /// No description provided for @notificationsExcursionGuestsUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest count updated'**
  String get notificationsExcursionGuestsUpdatedTitle;

  /// No description provided for @notificationsExcursionGuestsUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Open the guide dashboard to check the updated booking.'**
  String get notificationsExcursionGuestsUpdatedBody;

  /// No description provided for @notificationsExcursionAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Traveler checked in'**
  String get notificationsExcursionAttendanceTitle;

  /// No description provided for @notificationsExcursionAttendanceBody.
  ///
  /// In en, this message translates to:
  /// **'A traveler checked in for this excursion.'**
  String get notificationsExcursionAttendanceBody;

  /// No description provided for @notificationsExcursionCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion cancelled'**
  String get notificationsExcursionCancelledTitle;

  /// No description provided for @notificationsExcursionCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'The guide cancelled this excursion.'**
  String get notificationsExcursionCancelledBody;

  /// No description provided for @notificationsExcursionStartsSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion starts soon'**
  String get notificationsExcursionStartsSoonTitle;

  /// No description provided for @notificationsExcursionStartsSoonBody.
  ///
  /// In en, this message translates to:
  /// **'The booking window is closed. Open the excursion to check guests.'**
  String get notificationsExcursionStartsSoonBody;

  /// No description provided for @notificationsExcursionCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'How was your excursion?'**
  String get notificationsExcursionCompletedTitle;

  /// No description provided for @notificationsExcursionCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'The excursion is complete. You can leave a review.'**
  String get notificationsExcursionCompletedBody;

  /// No description provided for @notificationsExcursionPublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion published'**
  String get notificationsExcursionPublishedTitle;

  /// No description provided for @notificationsExcursionPublishedBody.
  ///
  /// In en, this message translates to:
  /// **'Your excursion is now visible to travelers.'**
  String get notificationsExcursionPublishedBody;

  /// No description provided for @notificationsExcursionRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Excursion needs changes'**
  String get notificationsExcursionRejectedTitle;

  /// No description provided for @notificationsExcursionRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Open the guide dashboard to check the review notes.'**
  String get notificationsExcursionRejectedBody;

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get notificationsJustNow;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String notificationsMinutesAgo(Object minutes);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String notificationsHoursAgo(Object hours);

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} d ago'**
  String notificationsDaysAgo(Object days);

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answers for bookings, guides, places, payments, currency, and account safety'**
  String get helpCenterSubtitle;

  /// No description provided for @helpCenterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Questions, tips, instructions'**
  String get helpCenterSearchHint;

  /// No description provided for @helpCenterCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get helpCenterCategoryAll;

  /// No description provided for @helpCenterCategoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get helpCenterCategoryDocuments;

  /// No description provided for @helpCenterCategoryFlights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get helpCenterCategoryFlights;

  /// No description provided for @helpCenterCategoryAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get helpCenterCategoryAccommodation;

  /// No description provided for @helpCenterCategoryMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get helpCenterCategoryMoney;

  /// No description provided for @helpCenterCategorySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get helpCenterCategorySafety;

  /// No description provided for @helpCenterCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get helpCenterCategoryTransport;

  /// No description provided for @helpCenterCategoryPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get helpCenterCategoryPlanning;

  /// No description provided for @helpCenterCategoryCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get helpCenterCategoryCulture;

  /// No description provided for @helpCenterMoreCategories.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get helpCenterMoreCategories;

  /// No description provided for @helpCenterCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get helpCenterCategoriesTitle;

  /// No description provided for @helpCenterPopularTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular answers'**
  String get helpCenterPopularTitle;

  /// No description provided for @helpCenterSearchResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get helpCenterSearchResultsTitle;

  /// No description provided for @helpCenterNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No answer found'**
  String get helpCenterNoResultsTitle;

  /// No description provided for @helpCenterNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another phrase or open Support requests if the answer is still missing'**
  String get helpCenterNoResultsMessage;

  /// No description provided for @helpCenterLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load help'**
  String get helpCenterLoadFailedTitle;

  /// No description provided for @helpCenterRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get helpCenterRetry;

  /// No description provided for @helpCenterLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get helpCenterLoadMore;

  /// No description provided for @helpCenterContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get helpCenterContactSupport;

  /// No description provided for @helpCenterOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get helpCenterOpenChat;

  /// No description provided for @helpCenterSupportChatButton.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get helpCenterSupportChatButton;

  /// No description provided for @helpCenterOpenRoute.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get helpCenterOpenRoute;

  /// No description provided for @helpCenterWasHelpful.
  ///
  /// In en, this message translates to:
  /// **'Was this helpful?'**
  String get helpCenterWasHelpful;

  /// No description provided for @helpCenterHelpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get helpCenterHelpful;

  /// No description provided for @helpCenterNotHelpful.
  ///
  /// In en, this message translates to:
  /// **'Not helpful'**
  String get helpCenterNotHelpful;

  /// No description provided for @helpCenterFeedbackSaved.
  ///
  /// In en, this message translates to:
  /// **'Thanks, your feedback helps improve answers'**
  String get helpCenterFeedbackSaved;

  /// No description provided for @supportRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track conversations with Inflap support and reply when we need more details'**
  String get supportRequestsSubtitle;

  /// No description provided for @supportRequestsLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests'**
  String get supportRequestsLoadFailedTitle;

  /// No description provided for @supportTicketDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Support chat'**
  String get supportTicketDetailTitle;

  /// No description provided for @supportTicketReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply'**
  String get supportTicketReplyHint;

  /// No description provided for @supportTicketClose.
  ///
  /// In en, this message translates to:
  /// **'Close request'**
  String get supportTicketClose;

  /// No description provided for @supportTicketNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get supportTicketNoMessagesTitle;

  /// No description provided for @supportTicketNoMessagesMessage.
  ///
  /// In en, this message translates to:
  /// **'Messages from support will appear here'**
  String get supportTicketNoMessagesMessage;

  /// No description provided for @supportReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your reply'**
  String get supportReplyFailed;

  /// No description provided for @supportTicketCSATTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate support'**
  String get supportTicketCSATTitle;

  /// No description provided for @supportTicketCSATCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get supportTicketCSATCommentHint;

  /// No description provided for @supportTicketCSATSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send rating'**
  String get supportTicketCSATSubmit;

  /// No description provided for @supportTicketCSATThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for rating support'**
  String get supportTicketCSATThanks;

  /// No description provided for @supportTicketCSATFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your rating'**
  String get supportTicketCSATFailed;

  /// No description provided for @supportEventTicketClosedByUser.
  ///
  /// In en, this message translates to:
  /// **'Request closed by user'**
  String get supportEventTicketClosedByUser;

  /// No description provided for @supportEventCSATSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Support rating submitted'**
  String get supportEventCSATSubmitted;

  /// No description provided for @supportEventTicketResolved.
  ///
  /// In en, this message translates to:
  /// **'Request resolved'**
  String get supportEventTicketResolved;

  /// No description provided for @supportEventSegmentCalculated.
  ///
  /// In en, this message translates to:
  /// **'Support context updated'**
  String get supportEventSegmentCalculated;

  /// No description provided for @supportEventUserReplied.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get supportEventUserReplied;

  /// No description provided for @supportEventAgentReplied.
  ///
  /// In en, this message translates to:
  /// **'Support replied'**
  String get supportEventAgentReplied;

  /// No description provided for @supportEventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Support request updated'**
  String get supportEventUpdated;

  /// No description provided for @supportStatusNew.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get supportStatusNew;

  /// No description provided for @supportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportStatusOpen;

  /// No description provided for @supportStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get supportStatusAssigned;

  /// No description provided for @supportStatusWaitingUser.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your reply'**
  String get supportStatusWaitingUser;

  /// No description provided for @supportStatusWaitingSupport.
  ///
  /// In en, this message translates to:
  /// **'Waiting for support'**
  String get supportStatusWaitingSupport;

  /// No description provided for @supportStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportStatusResolved;

  /// No description provided for @supportStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportStatusClosed;

  /// No description provided for @supportStatusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get supportStatusReopened;

  /// No description provided for @supportPreviewNew.
  ///
  /// In en, this message translates to:
  /// **'We received your request and will answer in this chat'**
  String get supportPreviewNew;

  /// No description provided for @supportPreviewWaitingUser.
  ///
  /// In en, this message translates to:
  /// **'Support needs more details from you'**
  String get supportPreviewWaitingUser;

  /// No description provided for @supportPreviewWaitingSupport.
  ///
  /// In en, this message translates to:
  /// **'Your reply was sent. Support will get back to you here.'**
  String get supportPreviewWaitingSupport;

  /// No description provided for @supportPreviewResolved.
  ///
  /// In en, this message translates to:
  /// **'This request is finished. You can rate support or create a new request.'**
  String get supportPreviewResolved;

  /// No description provided for @supportExpectedResponseWithin.
  ///
  /// In en, this message translates to:
  /// **'We usually answer within {time}'**
  String supportExpectedResponseWithin(Object time);

  /// No description provided for @supportMessageSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get supportMessageSending;

  /// No description provided for @supportMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get supportMessageSent;

  /// No description provided for @supportMessageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get supportMessageNotSent;

  /// No description provided for @supportMessageRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get supportMessageRetry;

  /// No description provided for @supportEpisodeNewRequestCreated.
  ///
  /// In en, this message translates to:
  /// **'Created new request'**
  String get supportEpisodeNewRequestCreated;

  /// No description provided for @supportEpisodeStarted.
  ///
  /// In en, this message translates to:
  /// **'Support request from {date}'**
  String supportEpisodeStarted(Object date);

  /// No description provided for @supportUserFallbackName.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportUserFallbackName;

  /// No description provided for @supportAgentFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportAgentFallbackName;

  /// No description provided for @supportSystemFallbackName.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get supportSystemFallbackName;

  /// No description provided for @contextualHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions and help'**
  String get contextualHelpTitle;

  /// No description provided for @contextualHelpOpenAll.
  ///
  /// In en, this message translates to:
  /// **'All help'**
  String get contextualHelpOpenAll;

  /// No description provided for @contextualHelpLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Help is temporarily unavailable'**
  String get contextualHelpLoadFailed;

  /// No description provided for @contextualHelpTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get contextualHelpTryAgain;
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
