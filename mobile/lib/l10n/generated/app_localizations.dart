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

  /// No description provided for @welcomeToFlyFy.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FlyFy'**
  String get welcomeToFlyFy;

  /// No description provided for @enterPhoneToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue'**
  String get enterPhoneToContinue;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @enterAuthCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Auth Code'**
  String get enterAuthCode;

  /// No description provided for @verifyAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyAndLogin;

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

  /// No description provided for @activityJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to join the activity'**
  String get activityJoinFailed;

  /// No description provided for @activityLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave the activity'**
  String get activityLeaveFailed;

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
  /// **'New Activity'**
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
  /// **'Basic Info'**
  String get createStepBasic;

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

  /// No description provided for @createStepNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get createStepNext;

  /// No description provided for @createStepBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get createStepBack;

  /// No description provided for @createBasicSection.
  ///
  /// In en, this message translates to:
  /// **'BASIC INFORMATION'**
  String get createBasicSection;

  /// No description provided for @createTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get createTitleLabel;

  /// No description provided for @createTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter activity title'**
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
  /// **'Describe what will happen at the activity'**
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
  /// **'e.g. sports, education, music'**
  String get createCategoryHint;

  /// No description provided for @createCategoryValidation.
  ///
  /// In en, this message translates to:
  /// **'Please specify a category'**
  String get createCategoryValidation;

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

  /// No description provided for @createMaxParticipantsValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid maximum number'**
  String get createMaxParticipantsValidation;

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

  /// No description provided for @createPriceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get createPriceAmountLabel;

  /// No description provided for @createCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get createCurrencyLabel;

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

  /// No description provided for @createOfflineSection.
  ///
  /// In en, this message translates to:
  /// **'VENUE'**
  String get createOfflineSection;

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
