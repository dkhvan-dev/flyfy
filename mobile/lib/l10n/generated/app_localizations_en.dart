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
  String get welcomeTitle => 'Your World,\nPersonalized.';

  @override
  String get welcomeDescription =>
      'Experience the ultimate travel super app designed for the modern explorer.';

  @override
  String get welcomeToFlyFy => 'Welcome to FlyFy';

  @override
  String get authByPhone => 'Sign in with Phone';

  @override
  String get termsAgreementText =>
      'By continuing, you agree to our <terms>Terms of Service</terms> and <privacy>Privacy Policy</privacy>';

  @override
  String get enterPhoneToContinue => 'Enter your phone number to continue';

  @override
  String get verifyAndLogin => 'Verify & Login';

  @override
  String get verifyYourPhone => 'Verify your phone';

  @override
  String get enterAuthCode => 'Enter the 6-digit code we just sent to\n';

  @override
  String get didntReceiveOTP => 'Didn\'t receive the code?';

  @override
  String get resendCode => 'Resend code';

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
  String get activityFormatLabel => 'Format';

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
  String get activityLeaveInlineButton => 'Leave Activity';

  @override
  String get activityCancelButton => 'Cancel activity';

  @override
  String get activityCancelConfirmTitle => 'Cancel this activity?';

  @override
  String get activityCancelConfirmDescription =>
      'Participants will see that the activity was cancelled. Add a reason so they understand what happened.';

  @override
  String get activityCancelReasonLabel => 'Cancellation reason';

  @override
  String get activityCancelReasonPlaceholder =>
      'For example: host is sick or the venue changed';

  @override
  String get activityCancelReasonRequired => 'Enter a cancellation reason';

  @override
  String get activityCancelKeepButton => 'Back';

  @override
  String get activityCancelConfirmButton => 'Confirm cancellation';

  @override
  String get activityJoinSuccess => 'You joined the activity';

  @override
  String get activityLeaveSuccess => 'You left the activity';

  @override
  String get activityCancelSuccess => 'Activity cancelled';

  @override
  String get activityJoinFailed => 'Failed to join the activity';

  @override
  String get activityJoinAlreadyJoined =>
      'You have already joined this activity';

  @override
  String get activityJoinScheduleConflict =>
      'You cannot join because you already have another activity at an overlapping time';

  @override
  String get activityLeaveFailed => 'Failed to leave the activity';

  @override
  String get activityCancelFailed => 'Failed to cancel the activity';

  @override
  String get activityCancelAlreadyCancelled =>
      'This activity is already cancelled';

  @override
  String get activityCancelNotAllowed =>
      'This activity can no longer be cancelled';

  @override
  String activityGoingTitle(int count) {
    return 'Going ($count)';
  }

  @override
  String get activityDetailsViewAll => 'View all';

  @override
  String get activityDetailsLinkCopied => 'Link copied';

  @override
  String get activityDetailsHostedBadge => 'Hosted by you';

  @override
  String get activityDetailsJoinedBadge => 'Joined';

  @override
  String get activityDetailsTotalLabel => 'Total';

  @override
  String get activityDetailsChatButton => 'Open chat';

  @override
  String get activityDetailsHostFallbackName => 'FlyFy Host';

  @override
  String get activityPaymentScreenTitle => 'FLYFY CHECKOUT';

  @override
  String get activityPaymentSummaryTitle => 'Activity Summary';

  @override
  String get activityPaymentBreakdownTitle => 'Price Breakdown';

  @override
  String get activityPaymentMethodTitle => 'Payment Method';

  @override
  String activityPaymentHostedBy(Object host) {
    return 'Hosted by $host';
  }

  @override
  String get activityPaymentAdmissionLabel => '1x Activity Access';

  @override
  String get activityPaymentServiceFeeLabel => 'Service Fee';

  @override
  String get activityPaymentSavedCardLabel => 'Saved Card';

  @override
  String get activityPaymentCardHolderFallback => 'FlyFy Member';

  @override
  String get activityPaymentApplePayLabel => 'Apple Pay';

  @override
  String get activityPaymentGooglePayLabel => 'Google Pay';

  @override
  String activityPaymentConfirmButton(Object amount) {
    return 'Confirm & Pay $amount';
  }

  @override
  String get activityPaymentSecureNote =>
      'Secure 256-bit SSL encrypted payment';

  @override
  String get activityPaymentPayButton => 'Pay';

  @override
  String get activityPaymentSuccess => 'Payment marked as paid';

  @override
  String get activityPaymentStatusLabel => 'Payment';

  @override
  String get activityPaymentPaidValue => 'PAID';

  @override
  String get activityParticipantFallbackName => 'Participant';

  @override
  String get activityParticipantsEmpty => 'No participants yet';

  @override
  String get activityParticipantsLoadFailed =>
      'Could not load participants right now';

  @override
  String get activityPrivateJoinTitle => 'Private Activity';

  @override
  String get activityPrivateJoinDescription =>
      'This activity is curated for a select group. Please enter the invitation password to join.';

  @override
  String get activityPrivateJoinPasswordLabel => 'Access Password';

  @override
  String get activityPrivateJoinPasswordPlaceholder => 'Enter access password';

  @override
  String get activityPrivateJoinPasswordValidation =>
      'Enter a password from 4 to 64 characters';

  @override
  String get activityPrivateJoinInvalidPassword =>
      'Incorrect password. Try again.';

  @override
  String get activityPrivateJoinSubmit => 'Verify & Join';

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
  String get homeCurrentLocationLabel => 'Current location';

  @override
  String homeExploringLocation(Object location) {
    return '$location';
  }

  @override
  String get homeSearchHint => 'Search destinations, stays or cars';

  @override
  String get homeTopDestinations => 'Top Destinations';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeRecommendedBlogs => 'Recommended Blogs';

  @override
  String get homeEditorialBadge => 'Editorial';

  @override
  String get homeStoryTitle => 'Hidden Gems of Central Asia';

  @override
  String get homeStoryDescription =>
      'Discover secret trails and cultural corners across Almaty\'s adventurous side.';

  @override
  String get homeReadStory => 'Read';

  @override
  String get homeFeaturedStays => 'Featured Stays';

  @override
  String get homeCarRentals => 'Car Rentals';

  @override
  String get homeRecommendedActivities => 'Recommended Activities';

  @override
  String get homeFilterButton => 'Filter';

  @override
  String get homeMoreButton => 'More';

  @override
  String get homeDestinationCharynTitle => 'Charyn Canyon';

  @override
  String get homeDestinationCharynSubtitle => 'Nature & Adventure';

  @override
  String get homeDestinationLakeTitle => 'Big Almaty Lake';

  @override
  String get homeDestinationLakeSubtitle => 'Scenic Views';

  @override
  String get homeDestinationKolsaiTitle => 'Kolsai Lakes';

  @override
  String get homeDestinationKolsaiSubtitle => 'Mountain Escape';

  @override
  String homeDurationHours(Object hours) {
    return '$hours h';
  }

  @override
  String get homeBookNow => 'Book Now';

  @override
  String get homeNavHome => 'Home';

  @override
  String get homeNavQr => 'QR';

  @override
  String get homeNavMap => 'Map';

  @override
  String get homeNavChats => 'Chats';

  @override
  String get homeNavMy => 'My';

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
  String get createActivityTitle => 'Create Activity';

  @override
  String get createActivitySubmit => 'Create Activity';

  @override
  String get createActivitySuccess => 'Activity created successfully';

  @override
  String get createActivityFailed => 'Failed to create activity';

  @override
  String get createStepBasic => 'Main Info';

  @override
  String get createStepDetailsLogistics => 'Details & Logistics';

  @override
  String get createStepRulesPricing => 'Rules & Pricing';

  @override
  String get createStepSchedule => 'Format & Schedule';

  @override
  String get createStepParticipation => 'Participation';

  @override
  String get createStepLocation => 'Location';

  @override
  String createStepCounter(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get createHelpAction => 'Help';

  @override
  String get createStepNext => 'Next Step';

  @override
  String get createStepBack => 'Back';

  @override
  String get createCoverSection => 'Upload Activity Cover';

  @override
  String get createCoverUploadTitle => 'Upload High-Res Image';

  @override
  String get createCoverChangeAction => 'Change Cover';

  @override
  String get createCoverUploadHint =>
      'JPG, PNG or WEBP. Recommended 1600x900px, max 20MB';

  @override
  String get createCoverUploadFailed =>
      'Failed to upload the cover image. Please try again.';

  @override
  String get createCoverUploadTooLarge =>
      'The image is too large. Maximum size is 20MB.';

  @override
  String get createCoverUploadUnsupportedFormat =>
      'Unsupported image format. Use JPG, PNG or WEBP.';

  @override
  String get createCoverUploadInProgress =>
      'Wait until the cover image upload finishes.';

  @override
  String get createCoverUploadRetryRequired =>
      'Upload the cover image again before continuing.';

  @override
  String get createBasicSection => 'BASIC INFORMATION';

  @override
  String get createTitleLabel => 'Activity Title';

  @override
  String get createTitleHint => 'e.g. Sunset Yoga by the Pier';

  @override
  String get createTitleValidation => 'Title must be at least 3 characters';

  @override
  String get createDescriptionLabel => 'Description';

  @override
  String get createDescriptionHint => 'Tell us more about the activity...';

  @override
  String get createDescriptionValidation =>
      'Description must be at least 10 characters';

  @override
  String get createCategoryLabel => 'Category';

  @override
  String get createCategoryHint => 'Select a category';

  @override
  String get createCategoryValidation => 'Please choose a category';

  @override
  String get createCategoryLoading => 'Loading categories';

  @override
  String get createCategoryLoadFailed => 'Failed to load categories';

  @override
  String get createCategoryEmpty => 'No categories available';

  @override
  String get createCategoryRetry => 'Retry';

  @override
  String get createCategoryPickerTitle => 'Choose Category';

  @override
  String get createCategoryApply => 'Apply Category';

  @override
  String get createTagsLabel => 'Tags';

  @override
  String get createTagsHint => 'Comma-separated: running, morning, park';

  @override
  String get createEventFormatLabel => 'Event Format';

  @override
  String get createFormatSection => 'FORMAT';

  @override
  String get createScheduleSection => 'SCHEDULE';

  @override
  String get createDatePartLabel => 'Date';

  @override
  String get createTimePartLabel => 'Time';

  @override
  String get createStartAtLabel => 'Start';

  @override
  String get createEndAtLabel => 'End';

  @override
  String get createStartDateLabel => 'Start date';

  @override
  String get createEndDateLabel => 'End date';

  @override
  String get createStartTimeLabel => 'Start time';

  @override
  String get createEndTimeLabel => 'End time';

  @override
  String get createScheduleInputValidation =>
      'Please enter a valid date and time';

  @override
  String get createRegistrationDeadlineLabel => 'Registration deadline';

  @override
  String get createEndDateValidation => 'End date must be after start date';

  @override
  String get createStartAtTooSoonValidation =>
      'Start time must be at least 1 hour from now';

  @override
  String get createRegistrationDeadlineValidation =>
      'Registration deadline must be before the start time';

  @override
  String get createRegistrationAutoHint =>
      'Registration closes automatically 1 hour before the activity starts';

  @override
  String get createSaveDraft => 'Save Draft';

  @override
  String get createAndPublish => 'Publish';

  @override
  String get createPublishActivityCta => 'Publish Activity';

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
  String get createActivityPrivacyTitle => 'Activity Privacy';

  @override
  String get createVisibilityPrivateWithPassword => 'Private with password';

  @override
  String get createVisibilityByLink => 'By link';

  @override
  String get createVisibilityPublicDescription =>
      'Visible to everyone on FlyFy';

  @override
  String get createVisibilityPrivateDescription =>
      'Only people with the code can see';

  @override
  String get createVisibilityUnlistedDescription =>
      'Accessible only via invite link';

  @override
  String get createVisibilityPickerTitle => 'Choose privacy';

  @override
  String get createVisibilityApply => 'Apply';

  @override
  String get createVisibilityPasswordLabel => 'Activity password';

  @override
  String get createVisibilityPasswordPlaceholder => 'Enter password';

  @override
  String get createVisibilityPasswordValidation =>
      'Enter a password from 4 to 64 characters';

  @override
  String get createVisibilityPasswordEditHint =>
      'Leave blank to keep the current password';

  @override
  String get createJoinModeSection => 'JOIN MODE';

  @override
  String get createJoinModeAuto => 'Auto approve';

  @override
  String get createJoinModeManual => 'Manual approve';

  @override
  String get createJoinApprovalTitle => 'Join Approval';

  @override
  String get createJoinModeAutomaticShort => 'Automatic';

  @override
  String get createJoinModeManualShort => 'Manual';

  @override
  String get createJoinModePickerTitle => 'Choose approval mode';

  @override
  String get createJoinModeApply => 'Apply';

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
  String get createParticipantLimitsTitle => 'Participant Limits';

  @override
  String get createUnlimitedParticipantsLabel => 'Unlimited participants';

  @override
  String get createParticipantsMinShort => 'MIN';

  @override
  String get createParticipantsMaxShort => 'MAX';

  @override
  String get createNoLimitPlaceholder => 'No limit';

  @override
  String get createMaxParticipantsValidation =>
      'Please enter a valid maximum number';

  @override
  String get createMinExceedsMaxValidation => 'Minimum cannot exceed maximum';

  @override
  String get createPriceSection => 'PRICING';

  @override
  String get createPriceFree => 'Free';

  @override
  String get createPricePaid => 'Paid';

  @override
  String get createPriceDeposit => 'Deposit';

  @override
  String get createPricingModelTitle => 'Pricing Model';

  @override
  String get createPriceAmountLabel => 'Amount';

  @override
  String get createPriceAmountOptionalLabel => 'Price amount (optional)';

  @override
  String get createPriceAmountPlaceholder => '\$ 0.00';

  @override
  String get createCurrencyLabel => 'Currency';

  @override
  String get createPricePerPersonHint => 'per person';

  @override
  String get createPriceValidation => 'Please enter a valid amount';

  @override
  String get createOnlineSection => 'ONLINE ACCESS';

  @override
  String get createOnlineAccessHint =>
      'Share the meeting link participants should use to join online';

  @override
  String get createMeetingUrlLabel => 'Meeting link';

  @override
  String get createMeetingUrlHint => 'https://zoom.us/...';

  @override
  String get createMeetingUrlValidation => 'Please provide a meeting link';

  @override
  String get createMeetingPointLocationLabel => 'Meeting point / Location';

  @override
  String get createMeetingPointTitle => 'MEETING POINT';

  @override
  String get createVenueOrAddressHint => 'Enter venue or address';

  @override
  String get createMapLinkLabel => 'Map Link';

  @override
  String get createMapLinkHint => 'Paste Maps URL';

  @override
  String get createOfflineSection => 'VENUE';

  @override
  String get createLocationPreviewHint =>
      'Add a city or address so participants know where to meet';

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
  String get createMapTapHint => 'Tap the map to pin the meeting point';

  @override
  String get createMapResolvingHint => 'Looking up the address...';

  @override
  String get createMapUnavailable =>
      'Google Maps preview is available in configured iOS and Android builds';

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

  @override
  String get myActivitiesTitle => 'My Activities';

  @override
  String get myActivitiesEmpty => 'You haven\'t created any activities yet';

  @override
  String get myActivitiesEmptyHint =>
      'Create your first activity and it will appear here';

  @override
  String get myActivitiesLoadFailed => 'Failed to load your activities';

  @override
  String get myActivitiesFilterAll => 'All';

  @override
  String myActivitiesLastUpdated(Object date) {
    return 'Last updated $date';
  }

  @override
  String get myActivitiesContinueButton => 'Continue';

  @override
  String get myActivitiesAttendedTab => 'Attended';

  @override
  String get myActivitiesAttendedEmpty =>
      'You haven\'t attended any activities yet';

  @override
  String get myActivitiesAttendedEmptyHint =>
      'Activities you join will appear here';

  @override
  String get myActivitiesAttendedLoadFailed =>
      'Failed to load attended activities';

  @override
  String get myActivitiesFilterButton => 'Filters';

  @override
  String get myActivitiesFilterTitle => 'Filters';

  @override
  String get myActivitiesFilterDateRange => 'Date Range';

  @override
  String get myActivitiesFilterStartDate => 'Start Date';

  @override
  String get myActivitiesFilterEndDate => 'End Date';

  @override
  String get myActivitiesFilterDatePlaceholder => 'dd.mm.yyyy';

  @override
  String get myActivitiesFilterDateHint =>
      'Enter the date manually in dd.mm.yyyy format';

  @override
  String get myActivitiesFilterInvalidDate => 'Enter a valid date';

  @override
  String get myActivitiesFilterInvalidRange =>
      'The end date cannot be earlier than the start date';

  @override
  String get myActivitiesFilterStatus => 'Filter by Status';

  @override
  String get myActivitiesFilterClear => 'Clear';

  @override
  String get myActivitiesFilterApply => 'Apply Filters';

  @override
  String get myActivitiesRecreateButton => 'Recreate';

  @override
  String get myActivitiesRestrictedButton => 'Edit Restricted';

  @override
  String get myActivitiesOpenButton => 'Open Activity';

  @override
  String get myActivitiesRetryButton => 'Try Again';

  @override
  String get myActivitiesPriceNoteFree => 'no fee';

  @override
  String get activityPerPerson => '/ person';

  @override
  String activitySpotsLeft(Object count) {
    return '$count Spots Left';
  }

  @override
  String get activityUnlimitedSpots => 'Unlimited';

  @override
  String get activityMeetingPoint => 'Meeting Point';

  @override
  String get activityGetDirections => 'Get Directions';

  @override
  String get activityHostSection => 'Host';

  @override
  String get activityTotalCapacity => 'Total Capacity';

  @override
  String get activityPricing => 'Pricing';

  @override
  String activityPeopleMax(Object count) {
    return '$count People Max';
  }

  @override
  String get activityJoinActivity => 'Join Activity';

  @override
  String get activitiesSearchHint => 'Search activities, hosts, or cities';

  @override
  String get activitiesFilterCategory => 'Category';

  @override
  String get activitiesFilterDate => 'Date';

  @override
  String get activitiesFilterPricing => 'Pricing';

  @override
  String get activitiesFilterVisibility => 'Visibility';

  @override
  String get activitiesDiscoverTitle => 'Discover Activities';

  @override
  String get activitiesFilteredEmptyTitle =>
      'No activities match these filters';

  @override
  String get activitiesFilteredEmptySubtitle =>
      'Try widening the category, date range, or pricing filters';

  @override
  String activitiesResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
      zero: 'No activities',
    );
    return '$_temp0';
  }

  @override
  String get activitiesFiltersCategoriesTitle => 'Categories';

  @override
  String get activitiesFiltersSelectedCategories => 'Selected Categories';

  @override
  String activitiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
      zero: '0 activities',
    );
    return 'Show $_temp0';
  }

  @override
  String get activitiesAllCategories => 'All categories';

  @override
  String get activitiesFiltersPriceRangeTitle => 'Price Range';

  @override
  String get activitiesFiltersVisibilityTitle => 'Visibility';

  @override
  String get activitiesFilterMinPrice => 'Min Price';

  @override
  String get activitiesFilterMaxPrice => 'Max Price';

  @override
  String get activitiesDatePresetToday => 'Today';

  @override
  String get activitiesDatePresetTomorrow => 'Tomorrow';

  @override
  String get activitiesDatePresetThisWeekend => 'This Weekend';

  @override
  String get activitiesDatePresetThisWeek => 'This Week';

  @override
  String get activitiesDatePresetThisMonth => 'This Month';

  @override
  String get activityViewDetails => 'View Details';

  @override
  String get activityJoinSession => 'Join Session';

  @override
  String get activityGetLink => 'Get Link';

  @override
  String get activityAttendanceQrButton => 'Attendance QR';

  @override
  String get activityAttendanceQrTitle => 'Activity QR';

  @override
  String get activityAttendanceQrFallbackTitle => 'Activity';

  @override
  String get activityAttendanceQrSubtitle =>
      'Show this QR to participants so they can confirm arrival in the app.';

  @override
  String get activityAttendanceQrHelper =>
      'The QR refreshes automatically. Participants should scan the current code using the QR button in the bottom bar.';

  @override
  String get activityAttendanceQrLoadFailed => 'Failed to load the activity QR';

  @override
  String get activityAttendanceQrRefreshHint =>
      'The code refreshes automatically to reduce duplicates and screenshot reuse.';

  @override
  String get activityAttendanceQrRefreshing => 'Refreshing QR…';

  @override
  String activityAttendanceQrExpiresIn(Object seconds) {
    return 'Refresh in ${seconds}s';
  }

  @override
  String get qrScannerTitle => 'Scan QR';

  @override
  String get qrScannerSubtitle =>
      'Point your camera at the host QR to confirm that you arrived at the activity.';

  @override
  String get qrScannerReady => 'Point the camera at the QR code';

  @override
  String get qrScannerInvalidCode => 'This is not a FlyFy activity QR';

  @override
  String get qrScannerSessionUnavailable =>
      'Current session is unavailable. Reopen the screen and try again.';

  @override
  String get qrScannerAlreadyQueued =>
      'This check-in is already waiting to sync';

  @override
  String get qrScannerQueuedOffline =>
      'Check-in saved. It will sync when the connection is back.';

  @override
  String get qrScannerSuccess => 'Arrival confirmed';

  @override
  String get qrScannerAlreadyCheckedIn =>
      'You are already checked in to this activity';

  @override
  String get qrScannerNotRegistered =>
      'You are not registered for this activity';

  @override
  String get qrScannerNotEligible =>
      'Check-in is not available for this booking yet';

  @override
  String get qrScannerQrExpired =>
      'This QR already expired. Ask the host to open a new one.';

  @override
  String get qrScannerHostNotAllowed => 'The host cannot scan their own QR';

  @override
  String get qrScannerActivityUnavailable =>
      'Check-in is unavailable for this activity right now';

  @override
  String get qrScannerCameraUnavailable =>
      'Camera is unavailable. Check camera permission and try again.';

  @override
  String get qrScannerSyncNow => 'Sync now';

  @override
  String get qrScannerScanAgain => 'Scan again';

  @override
  String qrScannerPendingCount(Object count) {
    return 'Pending sync: $count';
  }

  @override
  String get qrScannerNoPending => 'No pending check-ins';
}
