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
  String get phoneRequiredError => 'Enter your phone number';

  @override
  String get phoneInvalidError => 'Enter a valid phone number';

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
  String get commonPaginationPrevious => 'Previous page';

  @override
  String get commonPaginationNext => 'Next page';

  @override
  String commonPaginationLabel(Object current, Object total) {
    return 'Page $current of $total';
  }

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
  String get guideVerificationTitle => 'Guide application';

  @override
  String guideVerificationStepCounter(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get guideVerificationStepIdentity => 'Identity';

  @override
  String get guideVerificationStepDocument => 'Document';

  @override
  String get guideVerificationStepLicense => 'Credentials';

  @override
  String get guideVerificationStepSubmit => 'Submit';

  @override
  String get guideVerificationHeroTitle => 'Verify your guide status';

  @override
  String get guideVerificationHeroSubtitle =>
      'Complete the form and upload your documents so we can review your profile and unlock professional guide features.';

  @override
  String get guideVerificationIdentitySection => 'Basic information';

  @override
  String get guideVerificationFullNameLabel => 'Full name';

  @override
  String get guideVerificationFullNameHint => 'Exactly as shown on your ID';

  @override
  String get guideVerificationBirthDateLabel => 'Date of birth';

  @override
  String get guideVerificationBirthDateHint => 'DD.MM.YYYY';

  @override
  String get guideVerificationNationalityLabel => 'Nationality';

  @override
  String get guideVerificationSelectCountry => 'Select country';

  @override
  String get guideVerificationIdentityNotice =>
      'We use these details only to verify your identity and guide status.';

  @override
  String get guideVerificationContinueToDocuments => 'Continue to documents';

  @override
  String get guideVerificationDocumentTypeLabel => 'Document type';

  @override
  String get guideVerificationPassport => 'Passport';

  @override
  String get guideVerificationNationalId => 'National ID';

  @override
  String get guideVerificationUploadPhotoTitle => 'Upload an identity document';

  @override
  String get guideVerificationUploadPhotoSubtitle =>
      'Provide a clear photo or scan of the front side of your document.';

  @override
  String get guideVerificationNoGlare => 'No glare';

  @override
  String get guideVerificationNoGlareHint =>
      'Take the photo in even light so every detail remains readable.';

  @override
  String get guideVerificationFullFrame => 'Full frame';

  @override
  String get guideVerificationFullFrameHint =>
      'All edges of the document should be visible in the image.';

  @override
  String get guideVerificationTapToCapturePassport =>
      'Tap to choose a document file';

  @override
  String get guideVerificationFileFormatsShort => 'JPG, PNG, PDF up to 10 MB';

  @override
  String get guideVerificationChooseFile => 'Choose file';

  @override
  String get guideVerificationDocumentConfirm =>
      'I confirm that this document is valid, not expired, and the photo provided is clearly legible for automated verification systems.';

  @override
  String get guideVerificationVerifyContinue => 'Continue verification';

  @override
  String get guideVerificationCredentialsTitle => 'Credentials and license';

  @override
  String get guideVerificationCredentialsSubtitle =>
      'Tell us which document confirms your experience and right to work as a guide.';

  @override
  String get guideVerificationLicenseLabel => 'Verification document type';

  @override
  String get guideVerificationSelectLicenseType => 'Select document type';

  @override
  String get guideVerificationOfficialTourGuideLicense =>
      'Official tour guide license';

  @override
  String get guideVerificationCityGuidePermit => 'City guide permit';

  @override
  String get guideVerificationMuseumAccreditation =>
      'Museum or venue accreditation';

  @override
  String get guideVerificationUploadLicenseTitle =>
      'Upload the supporting document';

  @override
  String get guideVerificationUploadLicenseSubtitle =>
      'A certificate, license, or other professional document works here.';

  @override
  String get guideVerificationAdditionalCertifications => 'Additional skills';

  @override
  String get guideVerificationUploadFirstAidTitle =>
      'Upload a first aid certificate';

  @override
  String get guideVerificationUploadFirstAidSubtitle =>
      'Optional: add a valid certificate to strengthen your application.';

  @override
  String get guideVerificationUploadLanguageTitle =>
      'Upload a language certificate';

  @override
  String get guideVerificationUploadLanguageSubtitle =>
      'Optional: add a certificate that confirms your language proficiency.';

  @override
  String get guideVerificationFirstAid => 'First aid';

  @override
  String get guideVerificationFirstAidHint =>
      'You have current first aid training or a valid certificate.';

  @override
  String get guideVerificationLanguageProficiency => 'Foreign languages';

  @override
  String get guideVerificationLanguageProficiencyHint =>
      'You can host activities and tours in more than one language.';

  @override
  String get guideVerificationTimelineTitle => 'Review timeline';

  @override
  String get guideVerificationTimelineText =>
      'We usually review applications within 1 to 3 business days. If we need more information, you will see it in your profile.';

  @override
  String get guideVerificationReviewHeroTitle =>
      'Review your details before sending';

  @override
  String get guideVerificationReviewHeroSubtitle =>
      'Make sure everything is correct. Once submitted, the application goes to review.';

  @override
  String get guideVerificationReviewTitle => 'Application summary';

  @override
  String get guideVerificationEditInfo => 'Edit';

  @override
  String get guideVerificationIdentityDocumentCard => 'Identity document';

  @override
  String get guideVerificationProfessionalLicenseCard =>
      'Professional document';

  @override
  String get guideVerificationFirstAidCertificateCard =>
      'First aid certificate';

  @override
  String get guideVerificationLanguageCertificateCard => 'Language certificate';

  @override
  String get guideVerificationVerifiedUpload => 'File uploaded';

  @override
  String get guideVerificationTermsTitle => 'Confirmation';

  @override
  String get guideVerificationTermsHeading =>
      'I confirm that the information is accurate';

  @override
  String get guideVerificationTermsBody =>
      'I understand that FlyFy may reject the application if any information is inaccurate or the uploaded documents are not suitable.';

  @override
  String get guideVerificationAgreement =>
      'I agree to document review and data processing for guide status verification.';

  @override
  String get guideVerificationSubmit => 'Submit application';

  @override
  String get guideVerificationReviewNote =>
      'After submission, you can track the application status in your profile.';

  @override
  String get guideVerificationPendingTitle =>
      'Your application is already under review';

  @override
  String get guideVerificationPendingSubtitle =>
      'We received your documents and are reviewing them now. You will see an update in your profile as soon as the status changes.';

  @override
  String get guideVerificationActiveTitle => 'Guide status is already verified';

  @override
  String get guideVerificationActiveSubtitle =>
      'Your profile is already active as a guide profile. No need to submit anything else.';

  @override
  String get guideVerificationRejectedTitle => 'Your application needs updates';

  @override
  String get guideVerificationRejectedSubtitle =>
      'The previous application was rejected. You can update the information and submit your documents again.';

  @override
  String get guideVerificationDraftSubtitle =>
      'You already have a saved draft application. Continue with the current data and send it for review when ready.';

  @override
  String get guideVerificationViewApplicationButton => 'View application';

  @override
  String get guideVerificationContinueButton => 'Continue';

  @override
  String get guideVerificationBackToProfile => 'Back to profile';

  @override
  String get guideVerificationFullNameRequired => 'Enter your full name';

  @override
  String get guideVerificationFullNameInvalid =>
      'Enter both first and last name';

  @override
  String get guideVerificationBirthDateRequired => 'Enter your date of birth';

  @override
  String get guideVerificationBirthDateInvalid =>
      'Enter a valid date in DD.MM.YYYY format';

  @override
  String get guideVerificationNationalityRequired => 'Select your nationality';

  @override
  String get guideVerificationIdentityFileRequired =>
      'Upload your identity document';

  @override
  String get guideVerificationProfessionalFileRequired =>
      'Upload your professional document';

  @override
  String get guideVerificationConfirmationRequired =>
      'Confirm that the document is valid and the photo is clearly legible';

  @override
  String get guideVerificationAgreementRequired =>
      'You need to agree to the document review';

  @override
  String get guideVerificationUploadFailed => 'Failed to upload file';

  @override
  String get guideVerificationUnsupportedFormat =>
      'Only JPG, PNG, WEBP, and PDF are supported';

  @override
  String get guideVerificationSubmitFailed => 'Failed to submit application';

  @override
  String get guideVerificationDocumentsRequired =>
      'Both an identity document and a professional document are required';

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
  String get appLockLoading => 'Checking your protected session';

  @override
  String get appLockSetupTitle => 'Create a PIN';

  @override
  String get appLockSetupDescription =>
      'You will use this PIN for quick access if the session expires after reopening the app.';

  @override
  String get appLockSetupConfirmDescription =>
      'Enter the PIN again to confirm and save it.';

  @override
  String get appLockSetupCreateButton => 'Continue';

  @override
  String get appLockSetupConfirmButton => 'Save PIN';

  @override
  String get appLockSetupMismatch => 'PIN codes do not match';

  @override
  String get appLockPinInvalid => 'Enter a 4-digit PIN';

  @override
  String get appLockPinIncorrect => 'Incorrect PIN';

  @override
  String get appLockUnlockTitle => 'Confirm sign in';

  @override
  String get appLockPinUnlockDescription =>
      'Enter your PIN to continue using the app.';

  @override
  String get appLockBiometricUnlockDescription =>
      'Confirm access with Face ID, your fingerprint, or another available biometric. After 3 failed attempts, PIN unlock will be shown.';

  @override
  String get appLockUsePinButton => 'Use PIN';

  @override
  String get appLockUnlockButton => 'Unlock';

  @override
  String get appLockRetryBiometricButton => 'Use biometrics';

  @override
  String get appLockBiometricEnableTitle => 'Enable biometric sign in?';

  @override
  String get appLockBiometricEnableDescription =>
      'Next time you can quickly confirm access with Face ID or your fingerprint.';

  @override
  String get appLockBiometricEnableButton => 'Enable';

  @override
  String get appLockBiometricSkipButton => 'Not now';

  @override
  String get appLockBiometricFailed =>
      'Biometric confirmation failed. Try again or switch to PIN.';

  @override
  String get appLockBiometricFallback =>
      'Biometric access is temporarily unavailable. Enter your PIN.';

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
  String get profileDisplayNameTaken => 'This display name is already taken';

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
  String get myProfileTitle => 'My Profile';

  @override
  String get profileLinkCopied => 'Profile link copied';

  @override
  String get profileVerifiedExplorer => 'VERIFIED GUIDE';

  @override
  String get profileGuideTitle => 'FlyFy Guide';

  @override
  String get profileEmptyBioPlaceholder =>
      'There is no public description yet. Once the profile is filled in, a short bio will appear here.';

  @override
  String get profileBecomeGuideTitle => 'Become a guide';

  @override
  String get profileBecomeGuideSubtitle =>
      'Soon you will be able to apply and unlock a professional guide profile here.';

  @override
  String get profileActivitiesStat => 'Activities';

  @override
  String get profileHostedCompletedStat => 'Completed as host';

  @override
  String get profileJoinedCompletedStat => 'Completed as participant';

  @override
  String get profileReviewsStat => 'Reviews';

  @override
  String get profileBlogsStat => 'Blogs';

  @override
  String get profileFollowersStat => 'Followers';

  @override
  String get profileFollowersTitle => 'Followers';

  @override
  String get profileFollowersSearchHint => 'Search followers';

  @override
  String get profileFollowersEmptyTitle => 'No followers yet';

  @override
  String get profileFollowersEmptySubtitle =>
      'When users follow this profile, they will appear here.';

  @override
  String get profileFollowersSearchEmptyTitle => 'Nothing found';

  @override
  String get profileFollowersSearchEmptySubtitle =>
      'Try a different query or clear the search.';

  @override
  String get profileFollowersLoadFailed => 'Failed to load followers';

  @override
  String get profileJourneyTitle => 'My journey';

  @override
  String get profileSavedItemsTitle => 'Saved items';

  @override
  String get profileSavedItemsSubtitle =>
      'Saved activities, places, and collections will appear here later.';

  @override
  String get profileBookingsTitle => 'My bookings';

  @override
  String get profileBookingsSubtitle =>
      'Orders and confirmed bookings will appear here soon.';

  @override
  String get profileMyActivitiesSubtitle =>
      'Manage your activities and track your participation.';

  @override
  String get profilePreferencesTitle => 'Preferences';

  @override
  String get profileNotificationsRowTitle => 'Notifications';

  @override
  String get profileNotificationsRowSubtitle =>
      'Push, email, and SMS updates for your activity flow.';

  @override
  String get profileSecurityRowTitle => 'Security & data';

  @override
  String get profileSecurityRowSubtitle =>
      'PIN, biometrics, and the protected local session.';

  @override
  String get profileHostedActivitiesTitle => 'Hosted activities';

  @override
  String get profileHostedActivitiesUnavailable =>
      'Public hosted activities will appear here once the backend exposes the author\'s public showcase.';

  @override
  String get profileBlogsTitle => 'Recent Blogs';

  @override
  String get profileBlogsUnavailable =>
      'Public notes and travel stories are not available in the app yet.';

  @override
  String get profileUnavailableTitle => 'Coming soon';

  @override
  String get profileFollowAction => 'Follow';

  @override
  String get profileFollowingAction => 'Following';

  @override
  String get profileFollowUpdateFailed => 'Failed to update follow status';

  @override
  String get profileMessageAction => 'Message';

  @override
  String get profileMessageOpenFailed =>
      'Failed to open chat. Please try again.';

  @override
  String get profileSettingsPageTitle => 'Settings';

  @override
  String get profileSaveChangesButton => 'Save changes';

  @override
  String get profileDeactivateAccountLabel => 'Deactivate account';

  @override
  String get profileSettingsAvatarDisabledHint =>
      'Profile photo editing will be available in a future update.';

  @override
  String get profileSettingsAvatarUploadHint =>
      'Tap the avatar or edit icon to choose a profile photo.';

  @override
  String get profileSettingsAvatarUploading =>
      'Uploading your new profile photo...';

  @override
  String get profileSettingsAvatarUploadFailed =>
      'Failed to upload profile photo';

  @override
  String get profileSettingsAvatarUnsupportedFormat =>
      'Profile photo must be JPG, PNG, or WEBP';

  @override
  String get profileSettingsDescriptionSection => 'Description';

  @override
  String get profileSettingsDetailsSection => 'Profile details';

  @override
  String get profileSettingsServiceCitiesSection => 'Service cities';

  @override
  String get profileSettingsServiceCitiesUnavailable =>
      'Public service cities are not supported by the backend yet, so this block stays inactive for now.';

  @override
  String get profileSettingsAddNew => 'Add new';

  @override
  String get profileSettingsSecuritySection => 'Security';

  @override
  String get profileSettingsSecurityPinTitle => 'PIN & biometrics';

  @override
  String get profileSettingsSecurityPinSubtitle =>
      'Open the security screen to manage your local sign-in protection.';

  @override
  String get profileAccountSectionTitle => 'Account';

  @override
  String get profileSettingsEditSubtitle =>
      'Update your name, photo, bio, and core profile details.';

  @override
  String get profileOverviewSectionTitle => 'Profile overview';

  @override
  String get profileMoreSectionTitle => 'More';

  @override
  String get profileGuideWorkspaceTitle => 'Guide workspace';

  @override
  String get profileGuideWorkspaceSubtitle =>
      'Professional guide tools are not available in the mobile app yet.';

  @override
  String get profileSupportTitle => 'Help & support';

  @override
  String get profileSupportSubtitle =>
      'Help center and support requests will be added later.';

  @override
  String get profileNotificationsPageTitle => 'Notifications';

  @override
  String get profileNotificationsHeroTitle => 'Stay in sync';

  @override
  String get profileNotificationsHeroSubtitle =>
      'Choose how FlyFy keeps you updated about activity changes, participation, and new opportunities.';

  @override
  String get profileNotificationsActivitySection =>
      'Activities & participation';

  @override
  String get profileNotificationsDiscoverySection => 'Discovery & offers';

  @override
  String get profileNotificationsPushTitle => 'Push notifications';

  @override
  String get profileNotificationsPushSubtitle =>
      'Instant updates for activities, status changes, and new messages.';

  @override
  String get profileNotificationsEmailTitle => 'Email notifications';

  @override
  String get profileNotificationsEmailSubtitle =>
      'Confirmations, reminders, and useful updates sent to your inbox.';

  @override
  String get profileNotificationsSmsTitle => 'SMS notifications';

  @override
  String get profileNotificationsSmsSubtitle =>
      'Short critical updates and confirmations by text message.';

  @override
  String get profileNotificationsMarketingTitle => 'Collections & offers';

  @override
  String get profileNotificationsMarketingSubtitle =>
      'Travel inspiration, place collections, and special FlyFy offers.';

  @override
  String get profileNotificationsDarkModeTitle => 'Dark mode';

  @override
  String get profileNotificationsDarkModeSubtitle =>
      'This setting will arrive later. For now the app uses the current product palette.';

  @override
  String get profileNotificationsSaveFailed =>
      'Failed to update notification settings';

  @override
  String get profileSecurityPageTitle => 'Security & data';

  @override
  String get profileSecurityHeroTitle => 'Protect access';

  @override
  String get profileSecurityHeroSubtitle =>
      'This section combines local unlock methods and upcoming account protection tools.';

  @override
  String get profileSecurityLocalAccessSection => 'Local access';

  @override
  String get profileSecurityAccountSection => 'Account protection';

  @override
  String get profileSecurityDataSection => 'Data & privacy';

  @override
  String get profileSecurityPinTitle => 'App PIN';

  @override
  String get profileSecurityPinEnabledSubtitle =>
      'A PIN is configured and is used for quick app unlock.';

  @override
  String get profileSecurityPinMissingSubtitle =>
      'No PIN is configured yet. The app will ask to create one after the next authentication.';

  @override
  String get profileSecurityBiometricTitle => 'Biometric unlock';

  @override
  String get profileSecurityBiometricSubtitle =>
      'Allow app unlock with Face ID, fingerprint, or other supported biometrics.';

  @override
  String get profileSecurityBiometricNeedsPin =>
      'An app PIN must be configured first.';

  @override
  String get profileSecurityBiometricUnavailable =>
      'Biometrics are not available or not configured on this device.';

  @override
  String get profileSecurityProtectedSessionTitle => 'Protected session';

  @override
  String get profileSecurityProtectedSessionSubtitle =>
      'A local session is stored. After restart, the app can be unlocked quickly.';

  @override
  String get profileSecurityNoStoredSessionSubtitle =>
      'No active stored session was found. Protection will turn on automatically after the next sign in.';

  @override
  String get profileSecurityTwoFactorTitle => 'Additional verification';

  @override
  String get profileSecurityTwoFactorSubtitle =>
      'Extra sign-in checks and sensitive action confirmation will be added later.';

  @override
  String get profileSecurityDataExportTitle => 'Data export';

  @override
  String get profileSecurityDataExportSubtitle =>
      'Exporting your data is not implemented on the backend yet.';

  @override
  String get profileSecurityDeleteTitle => 'Delete account';

  @override
  String get profileSecurityDeleteSubtitle =>
      'Managed account deletion will be added after the backend flow is ready.';

  @override
  String get profileStatusEnabled => 'Enabled';

  @override
  String get profileStatusDisabled => 'Disabled';

  @override
  String get profileDisabledSoon => 'Soon';

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
  String get activityStatusCompletedEarly => 'Completed early';

  @override
  String get activityStatusCancelled => 'Cancelled';

  @override
  String get activityStatusArchived => 'Archived';

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
  String get activityExtend30MinutesButton => 'Extend by 30 min';

  @override
  String get activityExtend60MinutesButton => 'Extend by 1 hour';

  @override
  String get activityExtendSuccess => 'Activity end time updated';

  @override
  String get activityExtendFailed => 'Failed to extend the activity';

  @override
  String get activityExtendNotAllowed =>
      'This activity can no longer be extended';

  @override
  String get activityCompleteNowButton => 'Complete now';

  @override
  String get activityCompleteSuccess => 'Activity completed';

  @override
  String get activityCompleteEarlySuccess =>
      'Activity completed earlier than planned';

  @override
  String get activityCompleteFailed => 'Failed to complete the activity';

  @override
  String get activityCompleteTooEarly =>
      'You can complete the activity only during the final 25% of its planned duration';

  @override
  String get activityCompleteNotAllowed =>
      'This activity cannot be completed right now';

  @override
  String get activityCompleteAlreadyCompleted =>
      'This activity is already completed';

  @override
  String get activityCompleteConfirmTitle => 'Complete this activity early?';

  @override
  String get activityCompleteConfirmDescription =>
      'The activity will end earlier than planned. Add a reason so participants understand why it finished ahead of schedule.';

  @override
  String get activityCompleteReasonLabel => 'Early completion reason';

  @override
  String get activityCompleteReasonPlaceholder =>
      'For example: the program finished earlier than expected';

  @override
  String get activityCompleteReasonRequired =>
      'Enter a reason for early completion';

  @override
  String get activityCompleteConfirmButton => 'Confirm completion';

  @override
  String get activityCompleteCancelInsteadTitle =>
      'This action will cancel the activity';

  @override
  String get activityCompleteCancelInsteadDescription =>
      'There is still too much time left before the planned end. If you continue now, participants will see the activity as cancelled, not completed. Add a cancellation reason.';

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
  String get participantStatusRequested => 'Requested';

  @override
  String get participantStatusApproved => 'Approved';

  @override
  String get participantStatusWaitlisted => 'Waitlisted';

  @override
  String get participantStatusPendingPayment => 'Awaiting payment';

  @override
  String get participantStatusConfirmed => 'Confirmed';

  @override
  String get participantStatusDeclined => 'Declined';

  @override
  String get participantStatusCancelled => 'Cancelled';

  @override
  String get participantStatusExpired => 'Expired';

  @override
  String get participantStatusCheckedIn => 'Checked in';

  @override
  String get participantStatusAttended => 'Attended';

  @override
  String get participantStatusNoShow => 'No show';

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
  String get homeSearchHint => 'Search activities, attractions, tours...';

  @override
  String get homeTopDestinations => 'Top Destinations';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeTopStories => 'Top Stories';

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
  String get homeServiceActivities => 'Activities';

  @override
  String get homeServiceStories => 'Stories';

  @override
  String get homeServiceAttractions => 'Attractions';

  @override
  String get homeServiceStays => 'Stays';

  @override
  String get homeServiceDelivery => 'Delivery';

  @override
  String get homeServiceTaxi => 'Taxi';

  @override
  String get homePromoExclusive => 'Exclusive';

  @override
  String get homePromoAdventure => 'Adventure';

  @override
  String get homePromoYachtTitle => 'Yacht Parties';

  @override
  String get homePromoYachtDescription =>
      'Experience luxury on the waves with our curated...';

  @override
  String get homePromoMountainTitle => 'Mountain Tours';

  @override
  String get homePromoMountainDescription =>
      'Scale scenic routes with local experts...';

  @override
  String get homePromoExplore => 'Explore';

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
  String get mapNearbyPlacesLabel => 'Nearby places';

  @override
  String get mapSearchingNearbyPlaces => 'Looking for nearby venues and places';

  @override
  String get mapPlacesLoadFailed => 'Failed to load nearby places';

  @override
  String get mapNoPlacesTitle => 'No nearby places found';

  @override
  String get mapNoPlacesSubtitle =>
      'Move the map or refresh your location to explore other nearby venues and points of interest.';

  @override
  String get mapTapPlaceHint =>
      'Tap a marker or place card to preview it and copy its link.';

  @override
  String get mapCopyPlaceLink => 'Copy link';

  @override
  String get mapPlaceLinkCopied => 'Place link copied';

  @override
  String get mapUsingFallbackLocation =>
      'Showing the map from a fallback location';

  @override
  String mapPlacesCount(int count) {
    return 'Places found: $count';
  }

  @override
  String get attractionsTitle => 'Discover attractions';

  @override
  String get attractionsSearchHint => 'Where to next?';

  @override
  String get attractionsLoadFailed => 'Failed to load attractions';

  @override
  String get attractionsSeeAll => 'See all';

  @override
  String get attractionsNoResults => 'No attractions found';

  @override
  String get attractionsFiltersTitle => 'Filters';

  @override
  String get attractionsSortLabel => 'Sort by';

  @override
  String get attractionsSortRating => 'Rating';

  @override
  String get attractionsSortDuration => 'Duration';

  @override
  String get attractionsSortPrice => 'Price';

  @override
  String get attractionFilterClearAll => 'Clear all';

  @override
  String get attractionFilterCategoriesSection => 'Categories';

  @override
  String get attractionFilterCategoryAll => 'All Spots';

  @override
  String get attractionFilterCategoryParks => 'Parks';

  @override
  String get attractionFilterCategoryMuseums => 'Museums';

  @override
  String get attractionFilterCategoryNature => 'Nature';

  @override
  String get attractionFilterCategoryHistory => 'History';

  @override
  String get attractionFilterCategoryAdventure => 'Adventure';

  @override
  String get attractionFilterMinRatingSection => 'Minimum rating';

  @override
  String get attractionFilterRatingAny => 'Any';

  @override
  String get attractionFilterDurationSection => 'Duration';

  @override
  String get attractionFilterDurationShort => 'Short < 2h';

  @override
  String get attractionFilterDurationMedium => 'Medium 2–5h';

  @override
  String get attractionFilterDurationFullDay => 'Full Day 5h+';

  @override
  String get attractionFilterDurationMultiDay => 'Multi-day';

  @override
  String get attractionFilterRangeSection => 'Specific range';

  @override
  String attractionFilterRangeValue(int min, int max) {
    return '${min}h – ${max}h';
  }

  @override
  String get attractionFilterRangeMinTick => '1h';

  @override
  String get attractionFilterRangeMaxTick => '12h+';

  @override
  String get attractionFilterPriceRangeSection => 'Price range';

  @override
  String attractionFilterShowSpots(int count) {
    return 'Show $count spots';
  }

  @override
  String get attractionFilterClear => 'Clear';

  @override
  String get attractionMinPriceLabel => 'Min price';

  @override
  String get attractionMaxPriceLabel => 'Max price';

  @override
  String get attractionPriceValidationError => 'Enter a valid price';

  @override
  String get attractionPriceRangeValidationError =>
      'Max price must be greater than min price';

  @override
  String get attractionHoursUnit => 'Hours';

  @override
  String get attractionDaysUnit => 'Days';

  @override
  String get attractionHoursUnitShort => 'h';

  @override
  String get attractionDaysUnitShort => 'd';

  @override
  String get attractionMinLabel => 'Min';

  @override
  String get attractionMaxLabel => 'Max';

  @override
  String get attractionDurationValidationError => 'Enter a valid duration';

  @override
  String get attractionDurationRangeValidationError =>
      'Max duration must be greater than min';

  @override
  String get attractionDetailsLoadFailed => 'Failed to load attraction';

  @override
  String get attractionDetailsTitle => 'Attraction details';

  @override
  String get attractionMustVisitBadge => 'Must visit';

  @override
  String get attractionStatRating => 'Rating';

  @override
  String get attractionStatDuration => 'Duration';

  @override
  String get attractionStatPrice => 'Price';

  @override
  String get attractionExperienceSection => 'The experience';

  @override
  String get attractionExpectSection => 'What to expect';

  @override
  String get attractionVisitPlanSection => 'Plan your visit';

  @override
  String get attractionFlyFyTipTitle => 'FlyFy tip';

  @override
  String get attractionVisitDurationLabel => 'Time needed';

  @override
  String get attractionVisitDurationFlexible => 'Flexible';

  @override
  String get attractionVisitTicketsLabel => 'Tickets';

  @override
  String get attractionVisitFreeEntry => 'Free or varies';

  @override
  String get attractionVisitBookingRecommended => 'book ahead';

  @override
  String get attractionVisitBestTimeLabel => 'Best time';

  @override
  String get attractionVisitBestTimeEarlyMorning => 'Early morning';

  @override
  String get attractionVisitBestTimeMorning => 'Morning';

  @override
  String get attractionVisitBestTimeAfternoon => 'Afternoon';

  @override
  String get attractionVisitBestTimeSunset => 'Sunset';

  @override
  String get attractionVisitBestTimeAnytime => 'Anytime';

  @override
  String get attractionVisitGoodForLabel => 'Good for';

  @override
  String get attractionVisitAccessLabel => 'Access';

  @override
  String get attractionVisitAccessGood => 'Easy access';

  @override
  String get attractionVisitAccessLimited => 'Limited access';

  @override
  String get attractionVisitAccessUnknown => 'Check locally';

  @override
  String get attractionVisitSafetyLabel => 'Prepare';

  @override
  String get attractionVisitSafetyCheckWeather => 'Check weather';

  @override
  String get attractionVisitSafetyBringWater => 'Bring water';

  @override
  String get attractionVisitSafetyCheckHours => 'Check hours';

  @override
  String get attractionVisitAudienceCouples => 'Couples';

  @override
  String get attractionVisitAudienceWellness => 'Wellness';

  @override
  String get attractionVisitTipNature =>
      'Plan transport and weather before you go; guided routes are usually safer and more predictable.';

  @override
  String get attractionVisitTipCulture =>
      'Come earlier in the day for calmer photos and leave time for nearby cultural stops.';

  @override
  String get attractionVisitTipDefault =>
      'Check current hours and combine this stop with nearby activities to avoid losing time in transit.';

  @override
  String get attractionReviewsSection => 'Explorer\'s voice';

  @override
  String attractionSeeAllReviews(int count) {
    return 'See all ($count)';
  }

  @override
  String get attractionNoReviews => 'No reviews yet. Be the first!';

  @override
  String get attractionAddReview => 'Add review';

  @override
  String get attractionReviewSheetTitle => 'Share your visit';

  @override
  String get attractionReviewRatingLabel => 'Rating';

  @override
  String get attractionReviewCommentLabel => 'Comment';

  @override
  String get attractionReviewCommentHint =>
      'What stood out, what would you recommend, and what should others know?';

  @override
  String get attractionReviewAddPhoto => 'Photo';

  @override
  String get attractionReviewAddVideo => 'Video';

  @override
  String get attractionReviewSubmit => 'Publish review';

  @override
  String get attractionReviewSubmitting => 'Publishing...';

  @override
  String attractionReviewMediaLimit(int count) {
    return 'You can attach up to $count files';
  }

  @override
  String get attractionReviewPickFailed => 'Could not attach this file';

  @override
  String get attractionReviewMediaTooLarge => 'File is too large';

  @override
  String get attractionReviewUnsupportedFormat => 'Unsupported file format';

  @override
  String get attractionReviewSubmitFailed => 'Could not publish the review';

  @override
  String get attractionReviewSubmitSuccess => 'Review published';

  @override
  String get attractionReviewCommentRequired => 'Write a short comment';

  @override
  String get attractionReviewRemoveMedia => 'Remove file';

  @override
  String get attractionReviewVideoPreview => 'Video';

  @override
  String get attractionFindTours => 'Find tours';

  @override
  String get attractionMapLink => 'View on map';

  @override
  String get attractionVerifiedNomad => 'Verified nomad';

  @override
  String get attractionReviewsTitle => 'Reviews';

  @override
  String get attractionTravelerFallback => 'Traveler';

  @override
  String get attractionPriceVaries => 'Price varies';

  @override
  String get attractionPriceVariesShort => 'Varies';

  @override
  String attractionDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String attractionDurationDays(int days) {
    return '$days d';
  }

  @override
  String get attractionBackTooltip => 'Back';

  @override
  String get attractionNotificationsTooltip => 'Notifications';

  @override
  String get attractionBookmarkTooltip => 'Save attraction';

  @override
  String get attractionTagFamilyLabel => 'Family friendly';

  @override
  String get attractionTagFamilySubtitle => 'Suitable for all ages';

  @override
  String get attractionTagSunsetLabel => 'Best at sunset';

  @override
  String get attractionTagSunsetSubtitle => 'Stunning twilight views';

  @override
  String get attractionTagAccessibilityLabel => 'Accessibility';

  @override
  String get attractionTagAccessibilitySubtitle => 'Wheelchair friendly';

  @override
  String get attractionTagDiningLabel => 'Fine dining';

  @override
  String get attractionTagDiningSubtitle => 'Gourmet restaurants';

  @override
  String get attractionTagOutdoorLabel => 'Outdoor';

  @override
  String get attractionTagOutdoorSubtitle => 'Nature and fresh air';

  @override
  String get attractionTagPhotoLabel => 'Photo spot';

  @override
  String get attractionTagPhotoSubtitle => 'Great for memorable shots';

  @override
  String get attractionTagHistoryLabel => 'Historic';

  @override
  String get attractionTagHistorySubtitle => 'Rich cultural heritage';

  @override
  String get attractionTagAdventureLabel => 'Adventure';

  @override
  String get attractionTagAdventureSubtitle => 'Active experiences';

  @override
  String get attractionTagUniqueSubtitle => 'Unique experience';

  @override
  String get activitiesEntryTitle => 'Activities';

  @override
  String get activitiesEntrySubtitle =>
      'Find offline and online events you can join';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get change => 'Change';

  @override
  String get confirm => 'Confirm';

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
  String get toursDiscoverTitle => 'Discover Tours';

  @override
  String get toursSearchHint => 'Search tours and experiences';

  @override
  String get toursSortPopular => 'Popular';

  @override
  String get toursSortNewest => 'New';

  @override
  String get toursSortAffordable => 'Affordable';

  @override
  String get toursLoadFailed => 'Failed to load tours';

  @override
  String get toursEmptyTitle => 'No tours yet';

  @override
  String get toursEmptySubtitle => 'Verified guide routes will appear here.';

  @override
  String get toursEmptySearchSubtitle =>
      'Try another destination, category, or tour name.';

  @override
  String get toursCreateFab => 'Create tour';

  @override
  String get toursFreePrice => 'Free';

  @override
  String get toursDurationHourShort => 'h';

  @override
  String get toursDurationMinuteShort => 'min';

  @override
  String get tourDetailsTitle => 'Tour Details';

  @override
  String get tourDetailsPrice => 'Price';

  @override
  String get tourDetailsPerPerson => '/pp';

  @override
  String get tourDetailsIntensity => 'Intensity';

  @override
  String get tourDetailsIntensityModerate => 'Moderate';

  @override
  String get tourDetailsGroupSize => 'Group Size';

  @override
  String tourDetailsGroupSizeUpTo(Object count) {
    return 'Up to $count';
  }

  @override
  String get tourDetailsLanguage => 'Language';

  @override
  String get tourDetailsExperience => 'The Experience';

  @override
  String get tourDetailsWhatToExpect => 'What to expect';

  @override
  String get tourDetailsLeadGuide => 'Your Lead Guide';

  @override
  String get tourDetailsGuideName => 'FlyFy Guide';

  @override
  String get tourDetailsGuideSubtitle => 'Verified local expert';

  @override
  String get tourDetailsGuideQuote =>
      'Every route is more memorable with local context, thoughtful timing, and a guide who knows when to slow down.';

  @override
  String get tourDetailsMessageGuide => 'Message Guide';

  @override
  String get tourDetailsMapPreview => 'Route meeting point';

  @override
  String get tourDetailsItinerary => 'Itinerary';

  @override
  String get tourDetailsMeetingPoint => 'Meeting point';

  @override
  String get tourDetailsTotal => 'Total';

  @override
  String get tourDetailsBook => 'Book';

  @override
  String get tourDetailsLoadFailed => 'Failed to load tour';

  @override
  String get tourDetailsBookingComingSoon =>
      'Tour booking will be available soon.';

  @override
  String get tourDetailsGuideChatComingSoon =>
      'Guide chat will be available soon.';

  @override
  String get tourDetailsNoDescription =>
      'Your guide will share the detailed experience soon.';

  @override
  String get createTourTitle => 'Create Tour';

  @override
  String get createTourSubmit => 'Submit for Review';

  @override
  String get createTourSuccess => 'Tour submitted successfully';

  @override
  String get createTourFailed => 'Failed to create tour';

  @override
  String get createTourSelectedLandmark => 'Selected Landmark';

  @override
  String get createTourLandmarkNameLabel => 'Landmark';

  @override
  String get createTourLandmarkNameHint => 'e.g. Medeu';

  @override
  String get createTourLandmarkValidation => 'Select or enter a landmark';

  @override
  String get createTourCategorization => 'Travel Categorization';

  @override
  String get createTourCategoryAdventure => 'Adventure';

  @override
  String get createTourCategoryCultural => 'Cultural';

  @override
  String get createTourCategoryCulinary => 'Culinary';

  @override
  String get createTourCategoryWellness => 'Wellness';

  @override
  String get createTourDetailedItinerary => 'Detailed Itinerary';

  @override
  String get createTourAddTimeSlot => 'Add Time Slot';

  @override
  String get createTourAutosaveHint =>
      'Auto-saving progress to your guide profile';

  @override
  String get createTourItineraryValidation =>
      'Add at least one complete itinerary slot';

  @override
  String get createTourDurationLabel => 'Duration';

  @override
  String get createTourDurationHint => 'e.g. 4 hours';

  @override
  String get createTourDurationValidation =>
      'Enter a duration of at least 15 minutes';

  @override
  String get createTourMaxGroupSizeLabel => 'Max Group Size';

  @override
  String get createTourMaxGroupSizeHint => 'e.g. 12';

  @override
  String get createTourGroupSizeValidation =>
      'Enter a group size from 1 to 100';

  @override
  String get createTourLanguagesLabel => 'Languages Spoken';

  @override
  String get createTourLanguagesHint => 'English, French, Japanese...';

  @override
  String get createTourLanguagesValidation => 'Add at least one tour language';

  @override
  String get createTourVisibilityTitle => 'Tour Visibility';

  @override
  String get createTourVisibilityPublicDescription =>
      'Visible to everyone in the FlyFy marketplace.';

  @override
  String get createTourVisibilityUnlistedDescription =>
      'Only users with the direct URL can view and book this tour.';

  @override
  String get createTourMeetingPointHint =>
      'Enter meeting address or landmark...';

  @override
  String get createTourSoulTitle => 'Soul of the Journey';

  @override
  String get createTourNameLabel => 'Tour Title';

  @override
  String get createTourNameHint => 'e.g. Almaty Mountain Escape';

  @override
  String get createTourSummaryLabel => 'Short Summary';

  @override
  String get createTourSummaryHint => 'A concise promise for travelers';

  @override
  String get createTourSummaryValidation =>
      'Summary must be at least 3 characters';

  @override
  String get createTourSoulHint =>
      'Describe the soul of this journey, hidden details, and the feeling of being there...';

  @override
  String get createTourDescriptionValidation =>
      'Description must be at least 20 characters';

  @override
  String get createTourInvestmentTitle => 'Investment Per Person';

  @override
  String get createTourCurrencyValidation => 'Enter a currency code';

  @override
  String get createTourIncludedItemsLabel => 'Included Items';

  @override
  String get createTourIncludedItemsHint =>
      'Comma-separated: Private SUV, picnic, tickets';

  @override
  String get createTourStartOffsetLabel => 'Start after, min';

  @override
  String get createTourSlotDurationLabel => 'Duration, min';

  @override
  String get createTourItineraryTitleLabel => 'Title';

  @override
  String get createTourItineraryTitleHint => 'e.g. Mountain Ascent';

  @override
  String get createTourItineraryDescriptionLabel => 'Description';

  @override
  String get createTourItineraryDescriptionHint =>
      'What happens during this part of the route';

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
  String createStartAtMonthLimitValidation(String date) {
    return 'Start date must be no later than $date';
  }

  @override
  String createEndAtMonthLimitValidation(String date) {
    return 'End date must be no later than $date';
  }

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
      'Please enter a maximum between 1 and 100 participants';

  @override
  String get createMinParticipantsValidation =>
      'Please enter a minimum of at least 2 participants';

  @override
  String get createMinExceedsMaxValidation => 'Minimum cannot exceed maximum';

  @override
  String get createPriceSection => 'PRICING';

  @override
  String get createPriceFree => 'Free';

  @override
  String get createPricePaid => 'Paid';

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
      'Price cannot be changed if other participants have already joined';

  @override
  String get myActivitiesTitle => 'My Activities';

  @override
  String get myStoriesTitle => 'My Stories';

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
  String get activitiesFiltersTitle => 'Filters';

  @override
  String get activitiesSortLabel => 'Sort by';

  @override
  String get activitiesSortDate => 'Date';

  @override
  String get activitiesSortPrice => 'Price';

  @override
  String get activitiesFilterCategory => 'Category';

  @override
  String get activitiesFilterDate => 'Date';

  @override
  String get activitiesFilterStartDatePlaceholder => '15.05.2026';

  @override
  String get activitiesFilterEndDatePlaceholder => '22.05.2026';

  @override
  String get activitiesFilterPricing => 'Pricing';

  @override
  String get activitiesFilterVisibility => 'Visibility';

  @override
  String get activitiesDiscoverTitle => 'Activities';

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
      'You are not a participant of this activity';

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

  @override
  String get retry => 'Retry';

  @override
  String get backButtonLabel => 'Back';

  @override
  String get storiesDiscoverTitle => 'Discover Stories';

  @override
  String get storiesNavLabel => 'Stories';

  @override
  String get storiesActivitiesNavLabel => 'Activities';

  @override
  String get storySearchHint => 'Search stories, authors, or places';

  @override
  String get storyFiltersTitle => 'Filters';

  @override
  String get storyFilterCategory => 'Category';

  @override
  String get storyFilterCountry => 'Country';

  @override
  String get storyFilterAll => 'All';

  @override
  String storiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stories',
      one: '1 story',
      zero: '0 stories',
    );
    return 'Show $_temp0';
  }

  @override
  String get storySortLabel => 'Sort by';

  @override
  String get storySortDate => 'Date';

  @override
  String get storySortViews => 'Views';

  @override
  String get storySortComments => 'Comments';

  @override
  String get storyCreateCta => 'Share Your Story';

  @override
  String get storyCreateFirst => 'Create the first story';

  @override
  String get storyEmptyTitle => 'No stories yet';

  @override
  String get storyEmptySubtitle =>
      'Be the first to publish a travel note, local guide, or visual essay.';

  @override
  String get storyLoadFailed => 'Failed to load stories';

  @override
  String get storyViewsSuffix => 'views';

  @override
  String get storyCategoryJournal => 'Journal';

  @override
  String get storyCategoryGuide => 'Guide';

  @override
  String get storyCategoryPhotoEssay => 'Photo Essay';

  @override
  String get storyCategoryCulinary => 'Culinary';

  @override
  String get storyDetailsTitle => 'Story Details';

  @override
  String get storyLinkCopied => 'Story link copied';

  @override
  String get storyShareFailed =>
      'Unable to open the share sheet. Please try again.';

  @override
  String get storyAuthorLabel => 'Author';

  @override
  String get storyFollowAction => 'Follow';

  @override
  String get storyFollowingAction => 'Following';

  @override
  String get storyStatViews => 'Views';

  @override
  String get storyStatLikes => 'Likes';

  @override
  String get storyStatComments => 'Comments';

  @override
  String get storyStatShares => 'Shares';

  @override
  String get storyTagsLabel => 'Tags';

  @override
  String get storyCommentHint => 'Leave a thoughtful comment';

  @override
  String get storyCommentsTitle => 'Comments';

  @override
  String get storyCommentsEmpty => 'No comments yet. Start the conversation.';

  @override
  String get storyCommentRateLimit =>
      'You can leave only one comment every 3 hours.';

  @override
  String storyCommentCooldownUntil(Object time) {
    return 'You can leave the next comment after $time.';
  }

  @override
  String get storyCommentLinkCopied => 'Comment link copied';

  @override
  String get storyCommentShareFailed =>
      'Unable to open the comment share sheet. Please try again.';

  @override
  String get storyCommentEditingTitle => 'Editing comment';

  @override
  String get storyCommentSaveAction => 'Save';

  @override
  String get storyCommentShareAction => 'Share';

  @override
  String get storyDeleteCommentTitle => 'Delete comment?';

  @override
  String get storyDeleteCommentMessage =>
      'This comment will be permanently removed.';

  @override
  String get storyDeleteCommentAction => 'Delete';

  @override
  String get storyRelatedEyebrow => 'Keep Exploring';

  @override
  String get storyRelatedTitle => 'Related Stories';

  @override
  String get storyRelatedEmpty => 'No related stories yet';

  @override
  String get storyViewAll => 'View all';

  @override
  String get storyEditAction => 'Edit Story';

  @override
  String get storyDeleteTitle => 'Delete story?';

  @override
  String get storyDeleteMessage =>
      'The story will be removed from public feed.';

  @override
  String get storyDeleteAction => 'Delete';

  @override
  String get storyCreateTitle => 'New Story';

  @override
  String get storyContinueAction => 'Continue';

  @override
  String get storyUpdateAction => 'Update Story';

  @override
  String get storyPublishAction => 'Publish Story';

  @override
  String get storySaveDraftAction => 'Save Draft';

  @override
  String get storySaveFailed => 'Failed to save story';

  @override
  String get storyCoverUploadTitle => 'Upload Cover Image';

  @override
  String get storyCoverUploadSubtitle =>
      'High-resolution cinematic landscape preferred';

  @override
  String get storyCoverRequired => 'Add a cover image';

  @override
  String get storyCoverUnsupported => 'This image format is not supported';

  @override
  String get storyCoverTooLarge =>
      'Cover image is too large. Use a file up to 20 MB.';

  @override
  String get storyCoverUploadFailed => 'Failed to upload cover image';

  @override
  String get storyTitleLabel => 'Story Title';

  @override
  String get storyTitleHint => 'e.g. Sunset Yoga by the Pier';

  @override
  String get storyTitleRequired => 'Enter a story title';

  @override
  String storyTitleTooLong(Object count) {
    return 'The title must not exceed $count characters';
  }

  @override
  String get storyPlacePrompt => 'Where did this story take place?';

  @override
  String get storyPlaceHint => 'Search city or country';

  @override
  String get storyCountryHint => 'Search country';

  @override
  String get storyCityHint => 'Search city';

  @override
  String get storyTagsFieldLabel => 'Tags';

  @override
  String get storyTagHint => 'Add a tag';

  @override
  String get storyTagsLimit => 'You can add up to 8 tags';

  @override
  String get storyCategoryLabel => 'Select Category';

  @override
  String get storyCategoryRequired => 'Select a story category';

  @override
  String get storyContentHint => 'Start your narrative here...';

  @override
  String get storyContinueSectionHint => 'Continue the story here...';

  @override
  String get storyContentRequired => 'Write the story body';

  @override
  String storyContentTooLong(Object count) {
    return 'The story body must not exceed $count characters';
  }

  @override
  String get storyCharacterCountLabel => 'Character Count';

  @override
  String get storyInlineImageAddAction => 'Add photo';

  @override
  String get storyInlineImageHint =>
      'Images will appear between story paragraphs.';

  @override
  String get storyContinueSectionLabel =>
      'Continue the text below or add more photos.';

  @override
  String get storyInlineImageUnsupported =>
      'This image format is not supported for story content.';

  @override
  String get storyInlineImageTooLarge =>
      'This image is too large. Choose a file up to 20 MB.';

  @override
  String get storyInlineImageUploadFailed =>
      'Unable to upload the image into the story. Please try again.';

  @override
  String get storyAiHintUnavailable => 'AI writing hints are not available yet';

  @override
  String get storyWritersNoteTitle => 'Writer\'s Note';

  @override
  String get storyWritersNoteBody =>
      'Try starting with a sensory detail. Instead of “I arrived in Tokyo,” describe the neon glow reflecting off the damp pavement in Shibuya.';

  @override
  String get chatListTitle => 'Chats';

  @override
  String get chatListLoadFailed => 'Failed to load chats';

  @override
  String get chatListEmpty => 'No conversations yet';

  @override
  String get chatFallbackTitle => 'Chat';

  @override
  String get chatGroupFallbackTitle => 'Group Chat';

  @override
  String get chatActivityFallbackTitle => 'Activity chat';

  @override
  String get chatActiveNow => 'ACTIVE NOW';

  @override
  String get chatPresenceOnline => 'online';

  @override
  String get chatPresenceOffline => 'offline';

  @override
  String get chatPresenceLastSeenJustNow => 'last seen just now';

  @override
  String chatPresenceLastSeenMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'last seen $count minutes ago',
      one: 'last seen 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String chatPresenceLastSeenHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'last seen $count hours ago',
      one: 'last seen 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String chatPresenceLastSeenDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'last seen $count days ago',
      one: 'last seen 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String chatParticipantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
      zero: 'No participants',
    );
    return '$_temp0';
  }

  @override
  String get chatPinnedMessageLabel => 'PINNED MESSAGE';

  @override
  String get chatPinAction => 'Pin';

  @override
  String get chatUnpinAction => 'Unpin';

  @override
  String get chatPinFailed => 'Failed to pin the message. Please try again.';

  @override
  String get chatUnpinFailed =>
      'Failed to unpin the message. Please try again.';

  @override
  String get chatDateToday => 'Today';

  @override
  String get chatDateYesterday => 'Yesterday';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String get chatDeleteAction => 'Delete';

  @override
  String get chatDeleteFailed =>
      'Failed to delete the message. Please try again.';

  @override
  String get chatEditedLabel => 'edited';

  @override
  String get chatUserFallbackName => 'User';

  @override
  String get chatReplyPreviewFallback => 'Message';

  @override
  String chatSystemUserJoined(Object name) {
    return '$name joined';
  }

  @override
  String chatSystemUserLeft(Object name) {
    return '$name left';
  }

  @override
  String get chatSystemUpdate => 'System update';

  @override
  String get chatAttachmentPhotoVideo => 'Photo / Video';

  @override
  String get chatAttachmentFile => 'File';

  @override
  String get chatAttachmentLocation => 'Location';

  @override
  String get chatAttachmentAudio => 'Audio';

  @override
  String get chatAttachmentTakePhoto => 'Take photo';

  @override
  String get chatAttachmentTakeVideo => 'Take video';

  @override
  String get chatAttachmentChooseFromGallery => 'Choose from gallery';

  @override
  String get chatAttachmentCameraTitle => 'Camera';

  @override
  String get chatAttachmentAttachTitle => 'Attach';

  @override
  String get chatAttachmentCancel => 'Cancel';

  @override
  String get chatAttachmentVideoTooLong =>
      'Video is too long. Use a clip up to 5 minutes.';

  @override
  String get chatComposerCameraButtonLabel => 'Camera';

  @override
  String get chatComposerAttachButtonLabel => 'Attach file';

  @override
  String get chatComposerEmojiButtonLabel => 'Emoji and stickers';

  @override
  String get chatComposerEmojiTab => 'Emoji';

  @override
  String get chatComposerStickerTab => 'Stickers';

  @override
  String get chatStickerMessage => 'Sticker';

  @override
  String get chatStickerCreateAction => 'Create';

  @override
  String get chatStickerCreated => 'Sticker added';

  @override
  String get chatStickerCreateFailed =>
      'Failed to create the sticker. Please try again.';

  @override
  String get chatStickerSendFailed =>
      'Failed to send the sticker. Please try again.';

  @override
  String get chatStickerLoadFailed => 'Could not load your stickers.';

  @override
  String get chatComposerPaste => 'Paste';

  @override
  String get chatComposerPasteImage => 'Paste image';

  @override
  String get chatClipboardEmpty => 'Nothing to paste';

  @override
  String get chatPasteImagePreviewTitle => 'Send pasted image';

  @override
  String get chatPasteSendImage => 'Send image';

  @override
  String get chatPasteSendSticker => 'Add as sticker';

  @override
  String get stickersTabRecent => 'Recent';

  @override
  String get stickersSearchHint => 'Search stickers';

  @override
  String get stickersEmptyRecent => 'No recent stickers yet';

  @override
  String get stickersEmptySearch => 'No stickers found';

  @override
  String get stickersLoadFailed => 'Could not load stickers';

  @override
  String get stickersRetry => 'Retry';

  @override
  String get stickersOpenPicker => 'Open stickers';

  @override
  String get chatStickerUnsupported =>
      'Use a JPG, PNG, or WebP image for stickers.';

  @override
  String get chatStickerTooLarge =>
      'Sticker image is too large. Use an image up to 5 MB.';

  @override
  String get chatCameraPhotoMode => 'Photo';

  @override
  String get chatCameraVideoMode => 'Video';

  @override
  String get chatCameraRecording => 'REC';

  @override
  String get chatCameraPermissionDenied =>
      'Camera and microphone access are required to capture chat media.';

  @override
  String get chatCameraUnavailable => 'Camera is unavailable on this device.';

  @override
  String get chatCameraCaptureFailed =>
      'Could not capture media. Please try again.';

  @override
  String get chatCameraFlipButtonLabel => 'Switch camera';

  @override
  String get chatCameraCloseButtonLabel => 'Close camera';

  @override
  String get chatCameraCapturePhotoButtonLabel => 'Take photo';

  @override
  String get chatCameraRecordVideoButtonLabel => 'Record video';

  @override
  String get chatCameraStopRecordingButtonLabel => 'Stop recording';

  @override
  String get chatAttachmentUploading => 'Uploading attachment...';

  @override
  String get chatAttachmentDownloading => 'Downloading...';

  @override
  String get chatAttachmentDownloaded => 'Downloaded. Tap again to open.';

  @override
  String get chatAttachmentDownloadedStatus => 'Downloaded';

  @override
  String get chatAttachmentNotDownloadedStatus => 'Tap to download';

  @override
  String get chatAttachmentDownloadFailed =>
      'Failed to download the file. Please try again.';

  @override
  String get chatAttachmentOpenFailed =>
      'Could not open this file on the device.';

  @override
  String get chatAttachmentUploadFailed =>
      'Failed to upload the attachment. Please try again.';

  @override
  String get chatAttachmentUnsupported =>
      'This file type is not supported for chat attachments.';

  @override
  String get chatAttachmentTooLarge =>
      'The attachment is too large. Use a file up to 25 MB.';

  @override
  String get chatComposerHint => 'Message...';

  @override
  String get chatComposerClosedHint => 'Chat is closed';

  @override
  String get chatActivityChatClosed => 'This activity chat is now read-only.';

  @override
  String get chatActivityChatClosedHistoryNotice =>
      'The activity has ended. Messages can no longer be sent in this chat.';

  @override
  String get chatVoiceMessage => 'Voice message';

  @override
  String get chatVoiceRecording => 'Recording voice message';

  @override
  String get chatVoiceRecordingLocked => 'Recording locked';

  @override
  String get chatVoicePreparingPreview => 'Preparing voice preview...';

  @override
  String get chatVoicePreview => 'Voice preview';

  @override
  String get chatVoiceSlideUpToLock => 'Slide up to lock recording';

  @override
  String get chatVoiceRecordPermissionDenied =>
      'Microphone access is required to record voice messages.';

  @override
  String get chatVoiceRecordFailed =>
      'Failed to record the voice message. Please try again.';

  @override
  String get chatVoicePlaybackFailed => 'Could not play this voice message.';

  @override
  String get chatVoiceTooShort => 'Voice message is too short.';

  @override
  String get chatReactionSheetTitle => 'Reaction';

  @override
  String get chatReactionFailed =>
      'Could not update the reaction. Please try again.';

  @override
  String get chatLoadFailed => 'Failed to load chat';

  @override
  String get chatParticipantsHostSection => 'HOST & ORGANIZER';

  @override
  String get chatParticipantsJoinedSection => 'JOINED PARTICIPANTS';

  @override
  String get chatParticipantHostStatus => 'host & organizer';

  @override
  String get chatParticipantYouStatus => 'you';

  @override
  String get chatParticipantJoinedStatus => 'joined participant';

  @override
  String get chatParticipantsEmpty => 'No other participants yet';

  @override
  String get chatSharedMediaTab => 'Media';

  @override
  String get chatSharedLinksTab => 'Links';

  @override
  String get chatSharedFilesTab => 'Files';

  @override
  String get chatSharedNoMediaTitle => 'No media yet';

  @override
  String get chatSharedNoMediaSubtitle =>
      'Photos and videos from this chat will appear here.';

  @override
  String get chatSharedNoLinksTitle => 'No links yet';

  @override
  String get chatSharedNoLinksSubtitle =>
      'Messages with links will be collected here.';

  @override
  String get chatSharedNoFilesTitle => 'No files yet';

  @override
  String get chatSharedNoFilesSubtitle =>
      'Documents and archives from this chat will appear here.';

  @override
  String chatSharedFileFallback(Object id) {
    return 'File $id';
  }

  @override
  String get chatSharedUnknownFile => 'Unknown file';

  @override
  String get chatSharedLoadFailed => 'Could not load content';

  @override
  String get chatSharedLoadFailedSubtitle =>
      'Please check the connection and retry.';

  @override
  String get chatSharedPartialLoadWarning =>
      'Some older shared items could not be loaded.';
}
