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

  @override
  String get detectLocationButton => 'Detect from location';

  @override
  String get useDetectedLocationTitle => 'Use detected location?';

  @override
  String useDetectedLocationDescription(Object location) {
    return 'We detected your location as: $location. Use it for your profile?';
  }

  @override
  String get locationDetectFailed => 'Failed to detect location';

  @override
  String get locationServicesDisabled =>
      'Location services are disabled on this device';

  @override
  String get locationPermissionDenied => 'Location permission was not granted';

  @override
  String get locationPermissionDeniedForever =>
      'Location access is blocked. Please enable it in device settings';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get useButton => 'Use';

  @override
  String get activitiesTitle => 'Activities';

  @override
  String get activitiesLoadFailed => 'Failed to load activities';

  @override
  String get noActivitiesYet => 'No activities yet';

  @override
  String get activitiesWillAppearHere => 'New activities will appear here';

  @override
  String get activityDetailsComingSoon =>
      'Activity details page is coming soon';

  @override
  String get detailsButton => 'Details';

  @override
  String get retryButton => 'Retry';

  @override
  String get freeLabel => 'Free';

  @override
  String get fromLabel => 'from';

  @override
  String get activityStatusDraft => 'Draft';

  @override
  String get activityStatusReviewRequired => 'Under review';

  @override
  String get activityStatusPublished => 'Published';

  @override
  String get activityStatusEnrollmentOpen => 'Open for registration';

  @override
  String get activityStatusFull => 'Full';

  @override
  String get activityStatusStarted => 'Started';

  @override
  String get activityStatusCompleted => 'Completed';

  @override
  String get activityStatusCancelled => 'Cancelled';

  @override
  String get activityFormatOffline => 'Offline';

  @override
  String get activityFormatOnline => 'Online';

  @override
  String get activityFormatHybrid => 'Hybrid';

  @override
  String get activityDetailsTitle => 'Activity';

  @override
  String get activityDetailsLoadFailed => 'Failed to load activity';

  @override
  String get activityNotFound => 'Activity not found';

  @override
  String get activityAboutSection => 'About';

  @override
  String get activityInfoSection => 'Information';

  @override
  String get activityTagsSection => 'Tags';

  @override
  String get activityAccessSection => 'Access and safety';

  @override
  String get activitySensitiveDetailsProtected =>
      'The exact location, online meeting link, and sensitive details are available only after joining or being approved.';

  @override
  String get activitySensitiveDetailsHint =>
      'This is done for the safety of participants and organizers.';

  @override
  String get activityDateAndTime => 'Date and time';

  @override
  String get activityCategory => 'Category';

  @override
  String get activityLanguage => 'Language';

  @override
  String get activityCapacity => 'Capacity';

  @override
  String get activityPrice => 'Price';

  @override
  String get activityLocation => 'Location';

  @override
  String get activityUnlimitedCapacity => 'Number of participants is unlimited';

  @override
  String get activityLimitedCapacity => 'Limited number of places';

  @override
  String get activityJoinButton => 'Join';

  @override
  String get activityLeaveButton => 'Leave';

  @override
  String get activityJoinSuccess => 'You joined the activity';

  @override
  String get activityLeaveSuccess => 'You left the activity';

  @override
  String get activityJoinFailed => 'Failed to join the activity';

  @override
  String get activityLeaveFailed => 'Failed to leave the activity';

  @override
  String get homeTitle => 'FlyFy';

  @override
  String get homeSubtitle =>
      'Travel, discover activities, and explore new experiences';

  @override
  String get servicesSectionTitle => 'Services';

  @override
  String get homeToursTitle => 'Tours';

  @override
  String get homeToursSubtitle => 'Choose interesting routes and trips';

  @override
  String get homeGuidesTitle => 'Guides';

  @override
  String get homeGuidesSubtitle => 'Find local guides and experts';

  @override
  String get homeHotelsTitle => 'Hotels';

  @override
  String get homeHotelsSubtitle =>
      'Book accommodation quickly and conveniently';

  @override
  String get homeTransportTitle => 'Transport';

  @override
  String get homeTransportSubtitle => 'Plan your trips in advance';

  @override
  String get activitiesEntryTitle => 'Activities';

  @override
  String get activitiesEntrySubtitle =>
      'Find offline and online events you can join';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get createActivityFab => 'Create';

  @override
  String get createActivityTitle => 'New Activity';

  @override
  String get createActivitySubmit => 'Create Activity';

  @override
  String get createActivitySuccess => 'Activity created successfully';

  @override
  String get createActivityFailed => 'Failed to create activity';

  @override
  String get createStepBasic => 'Basic Info';

  @override
  String get createStepSchedule => 'Format & Schedule';

  @override
  String get createStepParticipation => 'Participation';

  @override
  String get createStepLocation => 'Location';

  @override
  String get createStepNext => 'Next';

  @override
  String get createStepBack => 'Back';

  @override
  String get createBasicSection => 'BASIC INFORMATION';

  @override
  String get createTitleLabel => 'Title';

  @override
  String get createTitleHint => 'Enter activity title';

  @override
  String get createTitleValidation => 'Title must be at least 3 characters';

  @override
  String get createDescriptionLabel => 'Description';

  @override
  String get createDescriptionHint =>
      'Describe what will happen at the activity';

  @override
  String get createDescriptionValidation =>
      'Description must be at least 10 characters';

  @override
  String get createCategoryLabel => 'Category';

  @override
  String get createCategoryHint => 'e.g. sports, education, music';

  @override
  String get createCategoryValidation => 'Please specify a category';

  @override
  String get createTagsLabel => 'Tags';

  @override
  String get createTagsHint => 'Comma-separated: running, morning, park';

  @override
  String get createFormatSection => 'FORMAT';

  @override
  String get createScheduleSection => 'SCHEDULE';

  @override
  String get createStartAtLabel => 'Start';

  @override
  String get createEndAtLabel => 'End';

  @override
  String get createRegistrationDeadlineLabel => 'Registration deadline';

  @override
  String get createEndDateValidation => 'End date must be after start date';

  @override
  String get createLanguageSection => 'ACTIVITY LANGUAGE';

  @override
  String get createVisibilitySection => 'VISIBILITY';

  @override
  String get createVisibilityPublic => 'Public';

  @override
  String get createVisibilityPrivate => 'Private';

  @override
  String get createVisibilityUnlisted => 'Unlisted';

  @override
  String get createJoinModeSection => 'JOIN MODE';

  @override
  String get createJoinModeAuto => 'Auto approve';

  @override
  String get createJoinModeManual => 'Manual approve';

  @override
  String get createCapacitySection => 'CAPACITY';

  @override
  String get createCapacityUnlimited => 'Unlimited';

  @override
  String get createCapacityLimited => 'Limited';

  @override
  String get createMinParticipantsLabel => 'Minimum';

  @override
  String get createMaxParticipantsLabel => 'Maximum';

  @override
  String get createMaxParticipantsValidation =>
      'Please enter a valid maximum number';

  @override
  String get createPriceSection => 'PRICING';

  @override
  String get createPriceFree => 'Free';

  @override
  String get createPricePaid => 'Paid';

  @override
  String get createPriceDeposit => 'Deposit';

  @override
  String get createPriceAmountLabel => 'Amount';

  @override
  String get createCurrencyLabel => 'Currency';

  @override
  String get createPriceValidation => 'Please enter a valid amount';

  @override
  String get createOnlineSection => 'ONLINE ACCESS';

  @override
  String get createMeetingUrlLabel => 'Meeting link';

  @override
  String get createMeetingUrlHint => 'https://zoom.us/...';

  @override
  String get createMeetingUrlValidation => 'Please provide a meeting link';

  @override
  String get createOfflineSection => 'VENUE';

  @override
  String get createCountryLabel => 'Country';

  @override
  String get createCityLabel => 'City';

  @override
  String get createCityHint => 'e.g. Almaty';

  @override
  String get createAddressLabel => 'Address';

  @override
  String get createAddressHint => 'Street, building, etc.';

  @override
  String get createLocationValidation => 'Please specify a city or address';

  @override
  String get editActivityTitle => 'Edit Activity';

  @override
  String get editActivityButton => 'Edit';

  @override
  String get editActivitySubmit => 'Save Changes';

  @override
  String get editActivitySuccess => 'Activity updated successfully';

  @override
  String get editActivityFailed => 'Failed to update activity';

  @override
  String get activityPublishButton => 'Publish';

  @override
  String get activityPublishSuccess => 'Activity published successfully';

  @override
  String get activityPublishFailed => 'Failed to publish activity';

  @override
  String get editFormatLocked => 'Format cannot be changed after creation';

  @override
  String get editLocationLocked =>
      'Location cannot be changed after publication';

  @override
  String get editPriceRestrictionHint =>
      'Price cannot be changed if participants have already joined';
}
