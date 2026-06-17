// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Inflap';

  @override
  String get welcomeTitle => 'Your World,\nPersonalized.';

  @override
  String get welcomeDescription =>
      'Experience the ultimate travel super app designed for the modern explorer.';

  @override
  String get welcomeToInflap => 'Welcome to Inflap';

  @override
  String get authByPhone => 'Sign in with Phone';

  @override
  String get authLoginTab => 'Login';

  @override
  String get authRegisterTab => 'Register';

  @override
  String get authLoginTitle => 'Sign in to your account';

  @override
  String get authRegisterTitle => 'Create your account';

  @override
  String get authIdentifierLabel => 'Nickname or email';

  @override
  String get authIdentifierHint => '@nomad or traveler@example.com';

  @override
  String get authIdentifierRequiredError => 'Enter your nickname or email';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'traveler@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get authConfirmPasswordLabel => 'Repeat password';

  @override
  String get authLoginAction => 'Log in';

  @override
  String get authRegisterAction => 'Register';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authLoginFailed =>
      'Could not sign in. Check your details and try again.';

  @override
  String get authRegistrationFailed =>
      'Could not start registration. Check your details and try again.';

  @override
  String get authPasswordMismatchError => 'Passwords do not match';

  @override
  String get authForgotPasswordAction => 'Forgot password?';

  @override
  String get passwordResetTitle => 'Recover access';

  @override
  String get passwordResetRequestDescription =>
      'Enter your email or nickname. If the account exists, we will send a code to the linked email.';

  @override
  String get passwordResetVerifyDescription =>
      'Enter the code from the email and set a new account password.';

  @override
  String get passwordResetIdentifierLabel => 'Email or nickname';

  @override
  String get passwordResetIdentifierHint => '@nomad or traveler@example.com';

  @override
  String get passwordResetIdentifierRequiredError =>
      'Enter your email or nickname';

  @override
  String get passwordResetCodeLabel => 'Verification code';

  @override
  String get passwordResetCodeHint => '6 digits';

  @override
  String get passwordResetCodeRequiredError => 'Enter the verification code';

  @override
  String get passwordResetNewPasswordLabel => 'New password';

  @override
  String get passwordResetConfirmPasswordLabel => 'Repeat new password';

  @override
  String get passwordResetSendCodeAction => 'Send code';

  @override
  String get passwordResetResendCodeAction => 'Resend code';

  @override
  String passwordResetResendCodeCountdown(String time) {
    return 'Resend in $time';
  }

  @override
  String get passwordResetSavePasswordAction => 'Save password';

  @override
  String get passwordResetBackToLogin => 'Back to login';

  @override
  String get passwordResetStartFailed =>
      'Could not send the recovery code. Try again.';

  @override
  String get passwordResetVerifyFailed =>
      'Could not update the password. Check the code and try again.';

  @override
  String get passwordResetSentNotice =>
      'If the account exists, the code was sent to the linked email.';

  @override
  String get passwordResetSuccess =>
      'Password updated. Sign in with the new password.';

  @override
  String get emailRequiredError => 'Enter your email';

  @override
  String get emailInvalidError => 'Enter a valid email';

  @override
  String get passwordRequiredError => 'Enter your password';

  @override
  String get passwordWeakError =>
      'Password must contain at least 8 characters, letters, and digits';

  @override
  String get skip => 'Skip';

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
  String get verifyYourEmail => 'Verify your email';

  @override
  String get enterAuthCode => 'Enter the 6-digit code we just sent to\n';

  @override
  String get enterEmailAuthCode => 'Enter the 6-digit code we just sent to\n';

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
  String get serviceExcursions => 'Excursions';

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
  String get drawerStatusVerifiedGuide => 'Verified guide';

  @override
  String get drawerStatusGuide => 'Guide';

  @override
  String get drawerStatusGuideRevoked => 'Guide status revoked';

  @override
  String get drawerStatusTraveler => 'Traveler';

  @override
  String get drawerStatusCompleteProfile => 'Complete profile';

  @override
  String get profileNotAvailable => 'Profile is not available';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profilePhoneVerificationSection => 'Phone verification';

  @override
  String get profilePhoneVerificationTitle => 'Contact number';

  @override
  String get profilePhoneVerificationDescription =>
      'Verify your number by SMS so we can protect bookings and sensitive actions.';

  @override
  String get profilePhoneVerifiedTitle => 'Phone verified';

  @override
  String get profilePhoneVerifiedDescription =>
      'This number is used as a trusted contact for important actions.';

  @override
  String profilePhoneVerifiedAs(Object phone) {
    return 'Verified: $phone';
  }

  @override
  String profilePhoneCurrentVerifiedAs(Object phone) {
    return 'Current number: $phone';
  }

  @override
  String get profilePhoneSendCode => 'Send code';

  @override
  String profilePhoneCodeSentTo(Object phone) {
    return 'Code sent to $phone';
  }

  @override
  String get profilePhoneCodeHint => 'SMS code';

  @override
  String get profilePhoneVerifyCode => 'Verify phone';

  @override
  String get profilePhoneResendCode => 'Send again';

  @override
  String profilePhoneResendIn(Object seconds) {
    return 'Again in ${seconds}s';
  }

  @override
  String get profilePhoneChangeNumber => 'Change number';

  @override
  String get profilePhoneCancelChange => 'Keep current number';

  @override
  String get profilePhoneInvalid =>
      'Enter the number in international format, for example +77011234567.';

  @override
  String get profilePhoneAlreadyVerified =>
      'This number is already verified. Enter a different number.';

  @override
  String get profilePhoneUnavailable =>
      'This number is already used or unavailable.';

  @override
  String get profilePhoneCodeExpired => 'The code expired. Send a new code.';

  @override
  String get profilePhoneCodeInvalid => 'Invalid verification code.';

  @override
  String get profilePhoneVerificationLocked =>
      'Too many incorrect attempts. Request a new code later.';

  @override
  String get profilePhoneRateLimited =>
      'Too many attempts. Wait before sending again.';

  @override
  String get profilePhoneVerificationUnavailable =>
      'Phone verification is temporarily unavailable.';

  @override
  String get profilePhoneVerificationFailed =>
      'Failed to verify phone. Please try again.';

  @override
  String get profilePhoneCodeRequired => 'Enter the SMS code.';

  @override
  String get profilePhoneStartRequired =>
      'Send a code to the phone number first.';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileLocale => 'Language';

  @override
  String get profileTimezone => 'Time zone';

  @override
  String get profileTimezoneSearchHint => 'Time zone, city, or UTC';

  @override
  String get profileTimezoneNoResults => 'No time zones found';

  @override
  String profileTimezoneRecommendedForCountry(Object country) {
    return 'Recommended for $country';
  }

  @override
  String timeDisplayYourTime(Object time) {
    return 'Your time: $time';
  }

  @override
  String get profileCountry => 'Country';

  @override
  String get profileCurrency => 'Currency';

  @override
  String get profileCurrencySearchHint => 'Currency, code, or symbol';

  @override
  String get profileCurrencyNoResults => 'No currencies found';

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
  String get guideVerificationOfficialExcursionGuideLicense =>
      'Official excursion guide license';

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
      'You can host activities and excursions in more than one language.';

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
      'I understand that Inflap may reject the application if any information is inaccurate or the uploaded documents are not suitable.';

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
  String get profileIncompleteTitle => 'Profile is incomplete';

  @override
  String get profileIncompleteDescription =>
      'Fill in your nickname, first name, last name, and country to unlock all Inflap features';

  @override
  String get fillNowButton => 'Fill now';

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get saveProfileButton => 'Save';

  @override
  String get profileSaveFailed => 'Failed to save profile';

  @override
  String get profileNicknameTaken => 'This nickname is already taken';

  @override
  String get profileNicknameOneTimeHint =>
      'Nickname can be set only once. After saving, it cannot be changed.';

  @override
  String get profileNicknameChecking => 'Checking nickname...';

  @override
  String get profileNicknameAvailable => 'Nickname is available';

  @override
  String get profileNicknameCheckFailed =>
      'Could not check nickname. Try again.';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get nicknameRequired => 'Enter nickname';

  @override
  String get profileNicknameLockedDescription =>
      'Nickname can be set only once. After saving, it cannot be changed.';

  @override
  String get bioLabel => 'About';

  @override
  String get firstNameRequired => 'Enter first name';

  @override
  String get lastNameRequired => 'Enter last name';

  @override
  String get profileCountryRequired => 'Select your country';

  @override
  String get profileRequiredTitle => 'Complete your profile';

  @override
  String get profileRequiredDescription =>
      'To continue, enter your nickname, first name, last name, and country in your profile. This helps reduce fake accounts and increases trust between users.';

  @override
  String get myProfileTitle => 'My Profile';

  @override
  String get profileLinkCopied => 'Profile link copied';

  @override
  String get profileVerifiedExplorer => 'VERIFIED GUIDE';

  @override
  String get profileGuideTitle => 'Inflap Guide';

  @override
  String get profileGuideRatingLabel => 'Guide rating';

  @override
  String get profileEmptyBioPlaceholder =>
      'There is no public description yet. Once the profile is filled in, a short bio will appear here.';

  @override
  String get profileBecomeGuideTitle => 'Become a guide';

  @override
  String get profileBecomeGuideSubtitle =>
      'Soon you will be able to apply and unlock a professional guide profile here.';

  @override
  String get guideVerificationRevokedTitle => 'Guide status revoked';

  @override
  String get guideVerificationRevokedSubtitle =>
      'Your guide status was revoked by moderation. Guide tools and public offers are unavailable.';

  @override
  String guideVerificationRevokedSubtitleWithReason(Object reason) {
    return 'Your guide status was revoked by moderation. Reason: $reason';
  }

  @override
  String get guideVerificationRevokedButton => 'Status revoked';

  @override
  String get profileActivitiesStat => 'Activities';

  @override
  String get profileHostedCompletedStat => 'Completed as host';

  @override
  String get profileJoinedCompletedStat => 'Completed as participant';

  @override
  String get profileReviewsStat => 'Reviews';

  @override
  String get profileStoriesStat => 'Stories';

  @override
  String get profileFollowersStat => 'Followers';

  @override
  String get profileFollowersTitle => 'Followers';

  @override
  String get profileFollowersSearchHint => 'Followers';

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
  String get profileConnectionsTitle => 'Friends and following';

  @override
  String get profileConnectionsSubtitle =>
      'Manage your friends and the people you follow.';

  @override
  String get profileConnectionsSearchHint => 'People';

  @override
  String get profileConnectionsFriendsTab => 'Friends';

  @override
  String get profileConnectionsFollowingTab => 'Following';

  @override
  String get profileConnectionsFriendsEmptyTitle => 'No friends yet';

  @override
  String get profileConnectionsFriendsEmptySubtitle =>
      'When a friend request is accepted, that user will appear here.';

  @override
  String get profileConnectionsFollowingEmptyTitle => 'No following yet';

  @override
  String get profileConnectionsFollowingEmptySubtitle =>
      'People you follow will appear here.';

  @override
  String get profileConnectionsLoadFailed => 'Failed to load the list';

  @override
  String get profileConnectionsSortRecent => 'Recent';

  @override
  String get profileConnectionsSortName => 'Name';

  @override
  String get profileConnectionsFiltersTitle => 'Filters';

  @override
  String get profileConnectionsFiltersShowResults => 'Show results';

  @override
  String get profileConnectionsFilterOnlineOnly => 'Online only';

  @override
  String get profileConnectionsFilterOnlineOnlySubtitle =>
      'Show users who are currently online.';

  @override
  String get profileConnectionsFriendRequestsTitle => 'Friend requests';

  @override
  String get profileConnectionsFriendRequestsViewAll => 'All requests';

  @override
  String get profileConnectionsFriendRequestsEmptyTitle => 'No friend requests';

  @override
  String get profileConnectionsFriendRequestsEmptySubtitle =>
      'New incoming friend requests will appear here.';

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
      'Account protection, data export, and privacy controls.';

  @override
  String get profileHostedActivitiesTitle => 'Hosted activities';

  @override
  String get profileHostedActivitiesUnavailable =>
      'Public hosted activities will appear here once the backend exposes the author\'s public showcase.';

  @override
  String get profileRecentActivitiesTitle => 'Recent activities';

  @override
  String get profileViewAllActivities => 'All';

  @override
  String get profileActivitiesLoadFailed => 'Failed to load activities';

  @override
  String get profileActivitiesLoadFailedHint =>
      'Check your connection and try again.';

  @override
  String get profileActivitiesEmptyTitle => 'No activities yet';

  @override
  String get profileActivitiesEmptySubtitle =>
      'Completed public activities for this user will appear here.';

  @override
  String get profileUserActivitiesTitle => 'User activities';

  @override
  String get profileUserActivitiesHostedTab => 'Hosted';

  @override
  String get profileUserActivitiesVisitedTab => 'Visited';

  @override
  String get profileUserActivitiesHostedEmptyTitle =>
      'No hosted activities yet';

  @override
  String get profileUserActivitiesHostedEmptySubtitle =>
      'When this user completes a public activity as the host, it will appear here.';

  @override
  String get profileUserActivitiesVisitedEmptyTitle =>
      'No visited activities yet';

  @override
  String get profileUserActivitiesVisitedEmptySubtitle =>
      'When this user attends a completed public activity, it will appear here.';

  @override
  String get profilePopularStoriesTitle => 'Popular posts';

  @override
  String get profileViewAllStories => 'All';

  @override
  String get profileStoriesLoadFailed => 'Failed to load posts';

  @override
  String get profileStoriesLoadFailedHint =>
      'Check your connection and try again.';

  @override
  String get profileStoriesEmptyTitle => 'No posts yet';

  @override
  String get profileStoriesEmptySubtitle =>
      'Published posts from this user will appear here.';

  @override
  String get profileUserStoriesTitle => 'User posts';

  @override
  String get profileStoriesTitle => 'Recent posts';

  @override
  String get profileStoriesUnavailable =>
      'Public posts and travel articles are not available in the app yet.';

  @override
  String get profileUnavailableTitle => 'Coming soon';

  @override
  String get profileFollowAction => 'Follow';

  @override
  String get profileFollowingAction => 'Following';

  @override
  String get profileUnfollowTitle => 'Unfollow user?';

  @override
  String get profileUnfollowDescription =>
      'You will stop seeing this user\'s updates in your feed.';

  @override
  String get profileUnfollowConfirm => 'Unfollow';

  @override
  String get profileUnfollowAction => 'Stop following';

  @override
  String get profileFollowUpdateFailed => 'Failed to update follow status';

  @override
  String get profileAddFriendAction => 'Add friend';

  @override
  String get profileFriendRequestSentAction => 'Request sent';

  @override
  String get profileFriendRequestTitle => 'Friend request';

  @override
  String get profileFriendRequestAcceptAction => 'Add';

  @override
  String get profileFriendRequestDeclineAction => 'Decline';

  @override
  String get profileAcceptFriendAction => 'Accept';

  @override
  String get profileDeclineFriendAction => 'Decline';

  @override
  String get profileFriendsAction => 'Friends';

  @override
  String get profileRemoveFriendAction => 'Remove friend';

  @override
  String get profileRemoveFriendTitle => 'Remove friend?';

  @override
  String get profileRemoveFriendDescription =>
      'You will no longer be able to invite this user as a friend until a new request is accepted.';

  @override
  String get profileRemoveFriendConfirm => 'Remove';

  @override
  String get profileFriendshipUpdateFailed =>
      'Failed to update friendship status';

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
  String get profileGuideDashboardTitle => 'Guide dashboard';

  @override
  String get profileGuideDashboardSubtitle =>
      'Manage offers, client bookings, and completed excursions.';

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
      'Tune push, quiet hours, and fallback channels so Inflap sends what matters without getting noisy.';

  @override
  String get profileNotificationsDeliverySection => 'Push delivery';

  @override
  String get profileNotificationsCategoriesSection => 'Push categories';

  @override
  String get profileNotificationsQuietHoursSection => 'Quiet hours';

  @override
  String get profileNotificationsChannelsSection => 'Fallback channels';

  @override
  String get profileNotificationsActivitySection =>
      'Activities & participation';

  @override
  String get profileNotificationsDiscoverySection => 'Discovery & offers';

  @override
  String get profileNotificationsPushTitle => 'Push notifications';

  @override
  String get profileNotificationsPushSubtitle =>
      'Master push switch for this device. The in-app inbox will keep saving notifications.';

  @override
  String get profileNotificationsPushPausedTitle => 'Push is paused';

  @override
  String get profileNotificationsPushPausedSubtitle =>
      'We will stop sending device push, while important events remain available in the in-app notification center.';

  @override
  String get profileNotificationsPushEnabledStatus => 'Push enabled';

  @override
  String get profileNotificationsPushPausedStatus => 'Push paused';

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
  String get profileNotificationsActivityPushTitle => 'Activities';

  @override
  String get profileNotificationsActivityPushSubtitle =>
      'New participants, status changes, reschedules, and reminders for your activities.';

  @override
  String get profileNotificationsExcursionPushTitle => 'Excursions';

  @override
  String get profileNotificationsExcursionPushSubtitle =>
      'Bookings, schedule updates, requests, publishing statuses, and excursion events.';

  @override
  String get profileNotificationsChatPushTitle => 'Messages';

  @override
  String get profileNotificationsChatPushSubtitle =>
      'New messages, invitations, and important replies in chats.';

  @override
  String get profileNotificationsMarketingTitle => 'Collections & offers';

  @override
  String get profileNotificationsMarketingSubtitle =>
      'Travel inspiration, place collections, and personal offers. You can turn this off without losing service notifications.';

  @override
  String get profileNotificationsSystemTitle =>
      'System and security notifications';

  @override
  String get profileNotificationsSystemSubtitle =>
      'Important account security, payment, and access messages cannot be disabled in the app.';

  @override
  String get profileNotificationsQuietHoursTitle => 'Do not disturb';

  @override
  String profileNotificationsQuietHoursSubtitle(Object start, Object end) {
    return 'Regular push will stay quiet from $start to $end. Urgent high-priority notifications are delivered immediately.';
  }

  @override
  String get profileNotificationsQuietHoursStart => 'Starts';

  @override
  String get profileNotificationsQuietHoursEnd => 'Ends';

  @override
  String profileNotificationsQuietHoursTimezone(Object timezone) {
    return 'Using profile timezone: $timezone';
  }

  @override
  String get profileNotificationsQuietHoursEnabledStatus => 'Quiet hours on';

  @override
  String get profileNotificationsQuietHoursDisabledStatus => 'No quiet hours';

  @override
  String get profileNotificationsPreferencesLoadFailedTitle =>
      'Could not load push settings';

  @override
  String get profileNotificationsPreferencesLoadFailedSubtitle =>
      'Check your connection. Email and SMS can still be changed separately, but push settings are temporarily unavailable.';

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
      'This section will collect account protection tools, data export, and privacy controls.';

  @override
  String get profileSecurityAccountSection => 'Account protection';

  @override
  String get profileSecurityDataSection => 'Data & privacy';

  @override
  String get profileSecurityPasswordTitle => 'Change password';

  @override
  String get profileSecurityPasswordSubtitle =>
      'Confirm your current password and a one-time email code.';

  @override
  String get profileSecurityPasswordAction => 'Change';

  @override
  String get profileSecurityPasswordSheetTitle => 'Change password';

  @override
  String get profileSecurityPasswordSheetSubtitle =>
      'First confirm your current password. Then we will send a code to the linked email.';

  @override
  String get profileSecurityPasswordCurrentLabel => 'Current password';

  @override
  String get profileSecurityPasswordCurrentHint => 'Enter current password';

  @override
  String get profileSecurityPasswordCodeNotice =>
      'The code was sent to the verified account email.';

  @override
  String get profileSecurityPasswordNewLabel => 'New password';

  @override
  String get profileSecurityPasswordConfirmLabel => 'Repeat new password';

  @override
  String get profileSecurityPasswordSendCode => 'Send code';

  @override
  String get profileSecurityPasswordSave => 'Save password';

  @override
  String get profileSecurityPasswordSuccess => 'Password changed.';

  @override
  String get profileSecurityPasswordChangeFailed =>
      'Could not change the password. Check the details and try again.';

  @override
  String get profileSecurityPasswordMismatchError => 'Passwords do not match';

  @override
  String get profileSecurityPasswordUnchangedError =>
      'The new password must be different from the current one';

  @override
  String profileSecurityPasswordResendCodeCountdown(String time) {
    return 'Resend in $time';
  }

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
  String get activityInviteFriendsButton => 'Invite friends';

  @override
  String get activityInviteFriendsTitle => 'Invite friends';

  @override
  String get activityInviteFriendsSearchHint => 'Friends';

  @override
  String get activityInviteFriendsEmptyTitle => 'No friends to invite';

  @override
  String get activityInviteFriendsEmptySubtitle =>
      'Add friends or try another search.';

  @override
  String get activityInviteFriendsLoadFailed => 'Could not load friends';

  @override
  String get activityInviteFriendsRetryHint =>
      'Check your connection and try again.';

  @override
  String activityInviteFriendsSend(int count) {
    return 'Invite ($count)';
  }

  @override
  String get activityInviteFriendsSuccess => 'Invitations sent';

  @override
  String get activityInviteFriendsFailed => 'Could not send invitations';

  @override
  String get activityInviteFriendsAuthRequired => 'Sign in to invite friends';

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
  String get activityDetailsHostFallbackName => 'Inflap Host';

  @override
  String get activityPaymentScreenTitle => 'INFLAP CHECKOUT';

  @override
  String get activityPaymentSummaryTitle => 'Activity Summary';

  @override
  String get activityPaymentBreakdownTitle => 'Price Breakdown';

  @override
  String get activityPaymentMethodTitle => 'Payment Method';

  @override
  String get activityPaymentMockNoticeTitle => 'Sandbox checkout';

  @override
  String get activityPaymentMockNoticeBody =>
      'Real payments are not connected yet. This screen only simulates a successful payment so the activity flow can be tested end to end.';

  @override
  String get activityPaymentSandboxMethodLabel => 'Sandbox confirmation';

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
  String get activityPaymentCardHolderFallback => 'Inflap Member';

  @override
  String get activityPaymentApplePayLabel => 'Apple Pay';

  @override
  String get activityPaymentGooglePayLabel => 'Google Pay';

  @override
  String activityPaymentConfirmButton(Object amount) {
    return 'Confirm mock payment $amount';
  }

  @override
  String get activityPaymentSecureNote =>
      'Secure 256-bit SSL encrypted payment';

  @override
  String get activityPaymentMockSecureNote =>
      'No card will be charged while payments are in sandbox mode.';

  @override
  String get activityPaymentPayButton => 'Mock payment';

  @override
  String get activityPaymentSuccess => 'Mock payment marked as paid';

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
  String get participantStatusInvited => 'Invited';

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
  String get homeTitle => 'Inflap';

  @override
  String get homeSubtitle =>
      'Travel, discover activities, and explore new experiences';

  @override
  String get servicesSectionTitle => 'Services';

  @override
  String get servicesAllButton => 'All';

  @override
  String get homeExcursionsTitle => 'Excursions';

  @override
  String get homeExcursionsSubtitle => 'Choose interesting routes and trips';

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
  String get homeLocationSheetTitle => 'Choose location';

  @override
  String get homeLocationSelected => 'Selected location';

  @override
  String get homeLocationUseCurrent => 'Use my current location';

  @override
  String get homeLocationDetecting => 'Detecting location...';

  @override
  String get homeLocationSearchHint => 'City';

  @override
  String get homeLocationNoResults => 'No cities found';

  @override
  String get homeLocationSearchFailed =>
      'Failed to search locations. Try again.';

  @override
  String get homeLocationDetectionFailed =>
      'Could not detect your location. Check location permissions and try again.';

  @override
  String get homeLocationApply => 'Apply location';

  @override
  String get locationFilterCitySection => 'City';

  @override
  String get locationFilterAllCities => 'All cities';

  @override
  String get locationFilterCitySearchHint => 'City';

  @override
  String get locationFilterCityNoResults => 'City not found';

  @override
  String get cityFilterEmptyHint => 'Try choosing another city in filters.';

  @override
  String homeExploringLocation(Object location) {
    return '$location';
  }

  @override
  String get homeSearchHint => 'Activities, attractions, excursions...';

  @override
  String get homeTopDestinations => 'Top Destinations';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeTopStories => 'Trending now';

  @override
  String get homeSmartPostsTitle => 'For you';

  @override
  String get homeSmartPostsEmpty => 'Posts picked for you will appear here.';

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
  String get homeServiceCurrencyConverter => 'Exchange Rates';

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
  String get homePromoMountainTitle => 'Mountain Excursions';

  @override
  String get homePromoMountainDescription =>
      'Scale scenic routes with local experts...';

  @override
  String get homePromoExplore => 'Explore';

  @override
  String get currencyConverterTitle => 'Currency Converter';

  @override
  String get currencyConverterSubtitle =>
      'Convert travel prices without leaving Inflap.';

  @override
  String get currencyConverterAmountLabel => 'Amount';

  @override
  String get currencyConverterFromLabel => 'From';

  @override
  String get currencyConverterToLabel => 'To';

  @override
  String get currencyConverterYouSend => 'You send';

  @override
  String get currencyConverterYouReceive => 'You receive';

  @override
  String get currencyConverterQuickSwitch => 'Quick switch';

  @override
  String get currencyConverterSelectCurrencyTitle => 'Select Currency';

  @override
  String get currencyConverterSearchCurrencyHint => 'Currency';

  @override
  String get currencyConverterRecentSection => 'Recent';

  @override
  String get currencyConverterAllCurrenciesSection => 'All currencies';

  @override
  String get currencyConverterNoCurrenciesFound => 'No currencies found';

  @override
  String get currencyConverterSwapTooltip => 'Swap currencies';

  @override
  String get currencyConverterConvertButton => 'Convert';

  @override
  String get currencyConverterLoading => 'Converting...';

  @override
  String get currencyConverterResultTitle => 'Result';

  @override
  String currencyConverterUpdatedAt(Object value) {
    return 'Rate updated $value';
  }

  @override
  String currencyConverterProvider(Object value) {
    return 'Provider: $value';
  }

  @override
  String get currencyConverterStaleWarning =>
      'Showing a fallback reference rate because the live provider is unavailable.';

  @override
  String get currencyConverterPopularPairs => 'Popular pairs';

  @override
  String get currencyConverterInfoNotice =>
      'Rates are informational and may differ from payment provider rates during checkout.';

  @override
  String get currencyConverterAmountValidation => 'Enter a valid amount';

  @override
  String get currencyConverterLoadFailed =>
      'Could not convert right now. Check the connection and try again.';

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
  String get feedNavLabel => 'Feed';

  @override
  String get homeNavQr => 'QR';

  @override
  String get homeNavMap => 'Map';

  @override
  String get homeNavChats => 'Chats';

  @override
  String get homeNavMy => 'My';

  @override
  String get feedTitle => 'Feed';

  @override
  String get feedTabForYou => 'For you';

  @override
  String get feedTabFollowing => 'Following';

  @override
  String get feedStoriesSectionTitle => 'Stories';

  @override
  String get feedCreateStoryAction => 'Your story';

  @override
  String get storyCaptureTitle => 'Add to story';

  @override
  String get storyCapturePreviewTitle => 'Preview';

  @override
  String get storyCaptureCloseLabel => 'Close';

  @override
  String get storyCaptureSettingsLabel => 'Settings';

  @override
  String get storyCaptureGalleryAction => 'Gallery';

  @override
  String get storyCapturePhotoFromGallery => 'Choose photo';

  @override
  String get storyCaptureVideoFromGallery => 'Choose video';

  @override
  String get storyCaptureCameraUnavailable =>
      'Camera is unavailable. Check permissions and try again.';

  @override
  String get storyCapturePermissionDenied =>
      'Camera or microphone access is denied.';

  @override
  String get storyCaptureCaptureFailed =>
      'Could not capture the story. Try again.';

  @override
  String get storyCaptureFlashOffLabel => 'Flash off';

  @override
  String get storyCaptureFlashAutoLabel => 'Auto flash';

  @override
  String get storyCaptureFlashOnLabel => 'Flash on';

  @override
  String get storyCaptureFlashUnsupported =>
      'Flash is not available for this camera.';

  @override
  String get storyCapturePhotoMode => 'Photo';

  @override
  String get storyCaptureVideoMode => 'Video';

  @override
  String get storyCaptureCaptureButtonLabel => 'Take photo';

  @override
  String get storyCaptureRecordButtonLabel => 'Record video';

  @override
  String get storyCaptureStopButtonLabel => 'Stop recording';

  @override
  String get storyCaptureFlipCameraLabel => 'Switch camera';

  @override
  String get storyCaptureCaptionHint => 'Add a caption...';

  @override
  String get storyCaptureRetakeAction => 'Retake';

  @override
  String get storyCapturePublishAction => 'Publish';

  @override
  String get storyCapturePublishing => 'Publishing...';

  @override
  String get storyCapturePublishFailed =>
      'Could not publish the story. Try again.';

  @override
  String get storyReplyInputHint => 'Reply';

  @override
  String get storyReplySendAction => 'Send reply';

  @override
  String get storyReplySentMessage => 'Reply sent';

  @override
  String get storyReplySendFailed => 'Could not send reply. Try again.';

  @override
  String get storyLikeAction => 'Like story';

  @override
  String get storyLikeSendFailed => 'Could not like the story. Try again.';

  @override
  String get storyCaptureDefaultTitle => 'My story';

  @override
  String get storyCaptureDefaultBody => 'New story';

  @override
  String get storyCaptureDefaultPlace => 'Story';

  @override
  String get storyCapturePublishedMessage => 'Story published';

  @override
  String get feedSuggestedCommunitiesTitle => 'Communities to follow';

  @override
  String get feedJoinCommunityAction => 'Join';

  @override
  String get feedCommunityJoinedAction => 'Following';

  @override
  String get feedCommunityModerationAction => 'Moderate';

  @override
  String get feedCommunityActionFailed =>
      'Could not update the subscription. Try again.';

  @override
  String feedCommunityMembersLabel(String count) {
    return '$count members';
  }

  @override
  String get feedMySubscriptionsTitle => 'My subscriptions';

  @override
  String feedMySubscriptionsSummary(int communities, int people) {
    return '$communities communities · $people people';
  }

  @override
  String get feedMySubscriptionsViewAll => 'View all';

  @override
  String get feedMySubscriptionsCommunitiesTab => 'Communities';

  @override
  String get feedMySubscriptionsPeopleTab => 'People';

  @override
  String get feedMySubscriptionsSearchHint => 'Subscriptions';

  @override
  String get feedMySubscriptionsSheetSubtitle =>
      'Communities, friends, and followed people you keep close in the feed.';

  @override
  String get feedMySubscriptionsFilterAll => 'All';

  @override
  String get feedMySubscriptionsFilterStatusSection => 'Subscription status';

  @override
  String get feedMySubscriptionsFilterPeopleSection => 'Connection type';

  @override
  String get feedMySubscriptionsFilterCommunityActivitySection => 'Activity';

  @override
  String get feedMySubscriptionsFilterCommunityTopicSection => 'Topics';

  @override
  String get feedMySubscriptionsFilterPeopleConnectionSection => 'Relationship';

  @override
  String get feedMySubscriptionsFilterPeopleActivitySection => 'Activity';

  @override
  String get feedMySubscriptionsFilterSortSection => 'Sort';

  @override
  String get feedMySubscriptionsFilterSubscribed => 'Subscribed';

  @override
  String get feedMySubscriptionsFilterUnsubscribed => 'Unsubscribed';

  @override
  String get feedMySubscriptionsFilterCurrentCity => 'My city';

  @override
  String get feedMySubscriptionsFilterActive => 'Has posts';

  @override
  String get feedMySubscriptionsFilterPopular => 'Popular';

  @override
  String get feedMySubscriptionsFilterFriends => 'Friends';

  @override
  String get feedMySubscriptionsFilterFollowing => 'Following';

  @override
  String get feedMySubscriptionsFilterOnline => 'Online';

  @override
  String get feedMySubscriptionsSortRelevant => 'Recommended';

  @override
  String get feedMySubscriptionsSortMostActive => 'Most active';

  @override
  String get feedMySubscriptionsSortMostPopular => 'Most followed';

  @override
  String get feedMySubscriptionsSortName => 'A-Z';

  @override
  String get feedMySubscriptionsSortOnlineFirst => 'Online first';

  @override
  String get feedPostSortRecommended => 'Recommended';

  @override
  String get feedPostSortNewest => 'Newest';

  @override
  String get feedPostSortPopular => 'Popular';

  @override
  String get feedPostSortDiscussed => 'Discussed';

  @override
  String get feedPostLikeAction => 'Like post';

  @override
  String get feedPostUnlikeAction => 'Remove like';

  @override
  String get feedPostShareAction => 'Share post';

  @override
  String get feedPostMoreActions => 'Post actions';

  @override
  String get feedPostHideAction => 'Hide post';

  @override
  String get feedPostNotInterestedAction => 'Not interested';

  @override
  String get feedPostActionFailed => 'Could not update the post. Try again.';

  @override
  String get feedMySubscriptionsApplyFilters => 'Apply filters';

  @override
  String feedMySubscriptionsShowCommunitiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count communities',
      one: 'Show $count community',
    );
    return '$_temp0';
  }

  @override
  String feedMySubscriptionsShowPeopleCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count people',
      one: 'Show $count person',
    );
    return '$_temp0';
  }

  @override
  String get feedMySubscriptionsEmptyMessage =>
      'No subscriptions match these filters.';

  @override
  String get feedMySubscriptionsFriendBadge => 'Friend';

  @override
  String get feedMySubscriptionsFollowingBadge => 'Following';

  @override
  String get feedMySubscriptionsOnlineBadge => 'Online';

  @override
  String get feedMySubscriptionsUnknownPerson => 'User';

  @override
  String get feedSystemPostsTitle => 'Official updates';

  @override
  String get feedSystemPostsViewAll => 'View all';

  @override
  String get feedSystemPostsSheetTitle => 'Official posts';

  @override
  String get communityDiscoveryTitle => 'Communities';

  @override
  String get communityDiscoveryEmptyTitle => 'No communities yet';

  @override
  String get communityDiscoveryEmptyMessage =>
      'Official communities will appear here as they launch.';

  @override
  String get communityDiscoveryLoadFailedTitle => 'Could not load communities';

  @override
  String get communityDiscoveryLoadFailedMessage =>
      'Check your connection and try again.';

  @override
  String get communityDiscoverySearchHint => 'Communities';

  @override
  String get communityDiscoveryFiltersTitle => 'Filters';

  @override
  String get communityDiscoveryShowResults => 'Show communities';

  @override
  String communityDiscoveryShowResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count communities',
      one: '1 community',
      zero: '0 communities',
    );
    return 'Show $_temp0';
  }

  @override
  String get communityDiscoveryRequiredLocationMessage =>
      'Choose a country and city to find active local communities.';

  @override
  String get communityDiscoveryTopicSection => 'Community type';

  @override
  String get communityDiscoveryTopicAll => 'All';

  @override
  String get communityDiscoveryTopicTravel => 'Travel';

  @override
  String get communityDiscoveryTopicCity => 'Cities';

  @override
  String get communityDiscoveryTopicGuides => 'Guides and tours';

  @override
  String get communityDiscoveryTopicAppNews => 'Inflap news';

  @override
  String get communityTopicLanguages => 'Languages';

  @override
  String get communityTopicHousing => 'Housing';

  @override
  String get communityTopicTransport => 'Transport';

  @override
  String get communityTopicSports => 'Sports';

  @override
  String get communityTopicOutdoor => 'Trips and outdoors';

  @override
  String get communityTopicHobbies => 'Hobbies and workshops';

  @override
  String get communityTopicWellness => 'Wellness';

  @override
  String get communityTopicPets => 'Pets';

  @override
  String get communityTopicCityLife => 'City life';

  @override
  String get communityTopicContent => 'News and guides';

  @override
  String get communityTopicFamily => 'Families';

  @override
  String get communityTopicGeneral => 'General';

  @override
  String get communityProfileTitle => 'Community';

  @override
  String get communityProfileActionsTooltip => 'Community actions';

  @override
  String get communityProfileCreatePostAction => 'Create post';

  @override
  String get communityPostModeSelectorLabel => 'Publishing mode';

  @override
  String get communityPostModeArticle => 'Posts';

  @override
  String get communityPostModeQuickPost => 'Discussions';

  @override
  String get communityPostModeListing => 'Listings';

  @override
  String get communityPostModeEventAnnouncement => 'Events';

  @override
  String get communityPostModeQuestionAnswer => 'Questions';

  @override
  String get communityPostModeTripPlan => 'Trips';

  @override
  String get communityProfileUnfollowConfirmTitle => 'Unfollow community?';

  @override
  String get communityProfileRulesTitle => 'Community rules';

  @override
  String get communityProfilePostsSectionTitle => 'Posts';

  @override
  String get communityProfileNoPostsTitle => 'No posts yet';

  @override
  String get communityProfileNoPostsMessage =>
      'New posts from this community will appear here.';

  @override
  String get communityProfilePostsLoadFailedTitle => 'Could not load posts';

  @override
  String communityProfilePostsLabel(String count) {
    return '$count posts';
  }

  @override
  String get communityProfileLoadFailedTitle => 'Could not load community';

  @override
  String get communityProfileLoadFailedMessage =>
      'Check your connection and try again.';

  @override
  String get communityTrustReportAction => 'Report community';

  @override
  String get communityTrustMuteAction => 'Mute community';

  @override
  String get communityTrustUnmuteAction => 'Unmute community';

  @override
  String get communityTrustBlockedTitle => 'Posting blocked';

  @override
  String get communityTrustBlockedMessage =>
      'You cannot post in this community until moderators lift the restriction.';

  @override
  String get communityTrustMutedTitle => 'Community muted';

  @override
  String get communityTrustMutedMessage =>
      'This community is muted in your feed. You can unmute it anytime.';

  @override
  String get communityTrustAppealPendingTitle => 'Appeal in review';

  @override
  String get communityTrustAppealPendingMessage =>
      'Moderators are reviewing your appeal for this community.';

  @override
  String get communityTrustAppealRejectedTitle => 'Appeal rejected';

  @override
  String get communityTrustAppealRejectedMessage =>
      'The restriction remains active after moderator review.';

  @override
  String get communityTrustAppealAction => 'Appeal';

  @override
  String get communityTrustAppealMessage =>
      'Please review my community restriction again.';

  @override
  String get communityTrustReportSubmitted => 'Community sent to moderation.';

  @override
  String get communityTrustMutedSubmitted => 'Community muted.';

  @override
  String get communityTrustUnmutedSubmitted => 'Community unmuted.';

  @override
  String get communityTrustAppealSubmitted => 'Appeal sent to moderators.';

  @override
  String get communityTrustActionUnavailable =>
      'This trust action is not available yet.';

  @override
  String get communityTrustActionFailed =>
      'Could not complete the trust action. Try again.';

  @override
  String get feedEmptyTitle => 'No feed items yet';

  @override
  String get feedEmptyMessage =>
      'Follow travelers and communities to shape your feed.';

  @override
  String get feedLoadFailedTitle => 'Could not load feed';

  @override
  String get feedLoadFailedMessage => 'Check your connection and try again.';

  @override
  String get feedRetryAction => 'Retry';

  @override
  String get communityModerationTitle => 'Moderation queue';

  @override
  String communityModerationSubtitle(int count) {
    return '$count pending';
  }

  @override
  String get communityModerationEmptyTitle => 'No posts waiting';

  @override
  String get communityModerationEmptyMessage =>
      'New community posts that need review will appear here.';

  @override
  String get communityModerationLoadFailedTitle =>
      'Could not load moderation queue';

  @override
  String get communityModerationLoadFailedMessage =>
      'Check your connection and try again.';

  @override
  String get communityModerationApproveAction => 'Approve';

  @override
  String get communityModerationRejectAction => 'Reject';

  @override
  String get communityModerationHistoryAction => 'History';

  @override
  String get communityModerationApprovedMessage => 'Post approved';

  @override
  String get communityModerationRejectedMessage => 'Post rejected';

  @override
  String get communityModerationActionFailed =>
      'Could not update this post. Try again.';

  @override
  String get communityModerationDecisionHistoryTitle => 'Decision history';

  @override
  String get communityModerationDecisionHistoryEmpty =>
      'No moderation decisions yet.';

  @override
  String get communityModerationDecisionHistoryFailed =>
      'Could not load decision history.';

  @override
  String get communityModerationRejectReasonLabel => 'Reason for rejection';

  @override
  String get communityModerationRejectConfirmAction => 'Reject post';

  @override
  String get communityModerationRejectCancelAction => 'Cancel';

  @override
  String get communityMembersTitle => 'Members';

  @override
  String get communityMembersSubtitle => 'Manage access and roles';

  @override
  String get communityMembersAction => 'Members';

  @override
  String get communityMembersEmptyTitle => 'No members found';

  @override
  String get communityMembersEmptyMessage =>
      'Members matching the selected filters will appear here.';

  @override
  String get communityMembersLoadFailedTitle => 'Could not load members';

  @override
  String get communityMembersLoadFailedMessage =>
      'Check your connection and try again.';

  @override
  String get communityMembersRoleFilterLabel => 'Role';

  @override
  String get communityMembersStatusFilterLabel => 'Status';

  @override
  String get communityMembersAllFilter => 'All';

  @override
  String get communityMembersActiveStatus => 'Active';

  @override
  String get communityMembersMutedStatus => 'Muted';

  @override
  String get communityMembersBannedStatus => 'Banned';

  @override
  String get communityMembersLeftStatus => 'Left';

  @override
  String get communityMembersTrustedRole => 'Trusted member';

  @override
  String get communityMembersModeratorRole => 'Moderator';

  @override
  String get communityMembersAdminRole => 'Admin';

  @override
  String get communityMembersMemberRole => 'Member';

  @override
  String get communityMembersChangeRoleAction => 'Change role';

  @override
  String get communityMembersRoleHistoryAction => 'Role history';

  @override
  String get communityMembersRoleHistoryTitle => 'Role history';

  @override
  String get communityMembersRoleHistoryChangedBy => 'Changed by';

  @override
  String get communityMembersRoleHistoryEmptyTitle => 'No role changes';

  @override
  String get communityMembersRoleHistoryEmptyMessage =>
      'Role updates for this member will appear here.';

  @override
  String get communityMembersRoleHistoryLoadFailedTitle =>
      'Could not load role history';

  @override
  String get communityMembersRoleHistoryLoadFailedMessage =>
      'Check your connection and try again.';

  @override
  String get communityMembersChangeStatusAction => 'Change status';

  @override
  String get communityMembersMuteAction => 'Mute member';

  @override
  String get communityMembersBanAction => 'Ban member';

  @override
  String get communityMembersRemoveAction => 'Remove member';

  @override
  String get communityMembersRestoreAction => 'Restore member';

  @override
  String get communityMembersStatusUpdatedMessage => 'Status updated';

  @override
  String get communityMembersStatusUpdateFailed =>
      'Could not update this member status. Try again.';

  @override
  String get communityMembersRoleUpdatedMessage => 'Role updated';

  @override
  String get communityMembersRoleUpdateFailed =>
      'Could not update this member. Try again.';

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
  String get mapDistancePending => 'Calculating distance';

  @override
  String mapPlacesCount(int count) {
    return 'Places found: $count';
  }

  @override
  String mapActivitiesCount(int count) {
    return 'Activities: $count';
  }

  @override
  String get mapTapActivityHint =>
      'Tap an activity marker to preview it and open details.';

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
  String get attractionsNoResultsSubtitle =>
      'Try choosing another city in filters.';

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
  String get attractionFilterCategoryArchitecture => 'Architecture';

  @override
  String get attractionFilterCategoryBeach => 'Beach';

  @override
  String get attractionFilterCategoryTemple => 'Temple';

  @override
  String get attractionFilterCategoryEntertainment => 'Entertainment';

  @override
  String get attractionFilterCategoryFood => 'Food';

  @override
  String get attractionFilterCategoryMarket => 'Market';

  @override
  String get attractionFilterCategoryShopping => 'Shopping';

  @override
  String get attractionFilterCategoryOther => 'Other';

  @override
  String get attractionFilterCategoryHistory => 'History';

  @override
  String get attractionFilterCategoryAdventure => 'Adventure';

  @override
  String get attractionFilterCountrySection => 'Country';

  @override
  String get attractionFilterCountryAll => 'All countries';

  @override
  String get attractionFilterCountrySearchHint => 'Country, code, or phone';

  @override
  String get attractionFilterCountryNoResults => 'Country not found';

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
  String get attractionInflapTipTitle => 'Inflap tip';

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
  String get attractionFindExcursions => 'Find excursions';

  @override
  String get attractionMapLink => 'View on map';

  @override
  String get attractionVerifiedNomad => 'Verified nomad';

  @override
  String get attractionReviewsTitle => 'Reviews';

  @override
  String get attractionTravelerFallback => 'Traveler';

  @override
  String get profileGuideReviewsTitle => 'Best excursion reviews';

  @override
  String get profileGuideReviewsLatestTitle => 'Latest excursion reviews';

  @override
  String get profileDirectGuideReviewsTitle => 'Guide rating';

  @override
  String get profileActivityOrganizerReviewsTitle =>
      'Activity organizer rating';

  @override
  String get profileActivityReviewsTitle => 'Activity reviews';

  @override
  String get profileGuideReviewsEmptyTitle => 'No reviews yet';

  @override
  String get profileGuideReviewsEmpty =>
      'Reviews will appear here after travelers rate completed excursions.';

  @override
  String get profileDirectGuideReviewsEmpty =>
      'Direct guide reviews will appear here after travelers rate the guide.';

  @override
  String get profileActivityOrganizerReviewsEmpty =>
      'Organizer reviews will appear here after participants rate completed activities.';

  @override
  String get profileActivityReviewsEmpty =>
      'Activity reviews will appear here after participants rate completed activities.';

  @override
  String get profileGuideReviewsLoadFailed => 'Could not load reviews';

  @override
  String get profileGuideReviewsLoadFailedHint =>
      'Pull to refresh or open the profile again.';

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
  String get select => 'Select';

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
  String get excursionsDiscoverTitle => 'Discover Excursions';

  @override
  String get excursionsSearchHint => 'Excursions and experiences';

  @override
  String get excursionsSortLabel => 'Sort by';

  @override
  String get excursionsSortPopular => 'Popular';

  @override
  String get excursionsSortNewest => 'New';

  @override
  String get excursionsSortAffordable => 'Affordable';

  @override
  String get excursionsSortCreatedAt => 'Created';

  @override
  String get excursionsSortRating => 'Rating';

  @override
  String get excursionsSortPrice => 'Price';

  @override
  String get excursionsSortDuration => 'Duration';

  @override
  String get excursionsFiltersTitle => 'Filters';

  @override
  String get excursionsFiltersClear => 'Clear';

  @override
  String excursionsFiltersShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count excursions',
      one: '1 excursion',
      zero: '0 excursions',
    );
    return 'Show $_temp0';
  }

  @override
  String get excursionsFilterCountry => 'Country';

  @override
  String get excursionsFilterCountryAll => 'All countries';

  @override
  String get excursionsFilterCountrySearchHint => 'Country, code, or phone';

  @override
  String get excursionsFilterCountryNoResults => 'Country not found';

  @override
  String get excursionsFilterCategories => 'Categories';

  @override
  String get excursionsFilterPriceRange => 'Price Range';

  @override
  String get excursionsFilterPriceFrom => 'From';

  @override
  String get excursionsFilterPriceTo => 'To';

  @override
  String get excursionsFilterBudget => 'Budget';

  @override
  String get excursionsFilterPremium => 'Premium';

  @override
  String get excursionsFilterDuration => 'Duration';

  @override
  String get excursionsFilterShortDuration => 'Short (< 3h)';

  @override
  String get excursionsFilterHalfDayDuration => 'Half Day (3–6h)';

  @override
  String get excursionsFilterFullDayDuration => 'Full Day (6h+)';

  @override
  String get excursionsFilterMultiDayDuration => 'Multi-day';

  @override
  String get excursionsFilterLanguage => 'Language';

  @override
  String get excursionsFilterLanguageAll => 'All languages';

  @override
  String get excursionsFilterLanguageSearchHint => 'Language or code';

  @override
  String get excursionsFilterLanguageNoResults => 'Language not found';

  @override
  String get excursionsLoadFailed => 'Failed to load excursions';

  @override
  String get excursionsEmptyTitle => 'No excursions yet';

  @override
  String get excursionsEmptySubtitle =>
      'Verified guide routes will appear here. Try choosing another city in filters.';

  @override
  String get excursionsEmptySearchSubtitle =>
      'Try another city, category, or excursion name.';

  @override
  String get excursionsNoAttractionExcursionsTitle =>
      'No excursions for this attraction yet';

  @override
  String get excursionsNoAttractionExcursionsSubtitle =>
      'Showing other available excursions. When guides add a route for this attraction, it will appear here.';

  @override
  String get guidesTitle => 'Travel Guides';

  @override
  String get guidesSearchHint => 'Guides';

  @override
  String get guidesSortLabel => 'Sort by';

  @override
  String get guidesSortRating => 'Rating';

  @override
  String get guidesSortExperience => 'Experience';

  @override
  String get guidesViewProfile => 'View Profile';

  @override
  String get guidesFiltersTitle => 'Filters';

  @override
  String get guidesFiltersClear => 'Clear';

  @override
  String get guidesClearSearch => 'Clear search';

  @override
  String get guidesFilterCountry => 'Country';

  @override
  String get guidesFilterCountryAll => 'All countries';

  @override
  String get guidesFilterCountrySearchHint => 'Country, code, or phone';

  @override
  String get guidesFilterCountryNoResults => 'Country not found';

  @override
  String get guidesFilterExpertise => 'Expertise';

  @override
  String get guidesFilterLanguage => 'Language';

  @override
  String get guidesFilterLanguageAll => 'All languages';

  @override
  String get guidesFilterLanguageSearchHint => 'Language or code';

  @override
  String get guidesFilterLanguageNoResults => 'Language not found';

  @override
  String get guidesFilterRating => 'Rating';

  @override
  String get guidesFilterExperience => 'Experience';

  @override
  String guidesFilterRatingAtLeast(Object value) {
    return '$value+ stars';
  }

  @override
  String guidesFiltersShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guides',
      one: '1 guide',
      zero: '0 guides',
    );
    return 'Show $_temp0';
  }

  @override
  String get guidesLoadFailed => 'Failed to load guides';

  @override
  String get guidesEmptyTitle => 'No guides yet';

  @override
  String get guidesEmptySubtitle =>
      'Verified local experts will appear here. Try choosing another city in filters.';

  @override
  String get guidesNoResultsTitle => 'No guides found';

  @override
  String get guidesNoResultsSubtitle =>
      'Try another city, name, expertise, language, or filter.';

  @override
  String get guidesRatingNew => 'New guide';

  @override
  String guidesReviewsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get guidesSpecialtyMountainGuide => 'Mountain Guide';

  @override
  String get guidesSpecialtyCityHistorian => 'City Historian';

  @override
  String get guidesSpecialtyCulinaryExpert => 'Culinary Expert';

  @override
  String get guidesSpecialtyNaturePhotographer => 'Nature Photographer';

  @override
  String get guidesRoleLocalExpert => 'Local Expert';

  @override
  String get guidesFilterPrivateExcursions => 'Private excursions';

  @override
  String get guidesFilterActivities => 'Activities';

  @override
  String get guidesFilterExcursions => 'Excursions';

  @override
  String guidesExperienceYears(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get excursionsCreateFab => 'Create excursion';

  @override
  String get excursionsFreePrice => 'Free';

  @override
  String excursionsPriceFrom(Object price) {
    return 'From $price';
  }

  @override
  String excursionsOffersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guides',
      one: '1 guide',
      zero: 'No guides yet',
    );
    return '$_temp0';
  }

  @override
  String get excursionsDurationHourShort => 'h';

  @override
  String get excursionsDurationMinuteShort => 'min';

  @override
  String get excursionDetailsTitle => 'Excursion Details';

  @override
  String get excursionDetailsPrice => 'Price';

  @override
  String get excursionDetailsPerPerson => '/pp';

  @override
  String get excursionDetailsIntensity => 'Intensity';

  @override
  String get excursionDetailsIntensityModerate => 'Moderate';

  @override
  String get excursionDetailsGroupSize => 'Group Size';

  @override
  String excursionDetailsGroupSizeUpTo(Object count) {
    return 'Up to $count';
  }

  @override
  String get excursionDetailsLanguage => 'Language';

  @override
  String get excursionLanguageEnglish => 'English';

  @override
  String get excursionLanguageRussian => 'Russian';

  @override
  String get excursionLanguageKazakh => 'Kazakh';

  @override
  String get excursionLanguageFrench => 'French';

  @override
  String get excursionLanguageJapanese => 'Japanese';

  @override
  String get excursionLanguageGerman => 'German';

  @override
  String get excursionLanguageSpanish => 'Spanish';

  @override
  String get excursionLanguageTurkish => 'Turkish';

  @override
  String get excursionDetailsExperience => 'Description';

  @override
  String get excursionDetailsWhatToExpect => 'What to expect';

  @override
  String get excursionDetailsSelectedOfferIncluded =>
      'Included with selected guide';

  @override
  String get excursionDetailsLeadGuide => 'Your Lead Guide';

  @override
  String get excursionDetailsGuideName => 'Guide';

  @override
  String get excursionDetailsGuideSubtitle => 'Verified local expert';

  @override
  String get excursionDetailsGuideQuote =>
      'Every route is more memorable with local context, thoughtful timing, and a guide who knows when to slow down.';

  @override
  String get excursionDetailsMessageGuide => 'Message Guide';

  @override
  String get excursionDetailsOffersTitle => 'Available guides';

  @override
  String get excursionDetailsOffersEmpty => 'No guides available yet';

  @override
  String get excursionDetailsOfferSelected => 'Selected';

  @override
  String get excursionDetailsOfferCurrentUser => 'This is you';

  @override
  String get excursionDetailsOffersSearchHint => 'Guides or offers';

  @override
  String get excursionDetailsOffersLoadMore => 'Show more guides';

  @override
  String get excursionDetailsOffersLoadFailed => 'Failed to load guides';

  @override
  String get excursionDetailsOffersSortRating => 'Rating';

  @override
  String get excursionDetailsOffersSortExperience => 'Experience';

  @override
  String get excursionDetailsOffersSortPrice => 'Price';

  @override
  String get excursionDetailsOffersFiltersTitle => 'Guide filters';

  @override
  String get excursionDetailsOffersMaxPrice => 'Max price';

  @override
  String get excursionDetailsOffersMaxPriceHint => 'e.g. 50000';

  @override
  String get excursionDetailsOffersAvailableDate => 'Available date';

  @override
  String get excursionDetailsOffersAvailableDateHint => 'dd.mm.yyyy';

  @override
  String get excursionDetailsOffersAvailableDateInvalid =>
      'Enter the date as dd.mm.yyyy';

  @override
  String get excursionDetailsOffersMinGroup => 'Minimum group size';

  @override
  String get excursionDetailsOffersMinGroupHint => 'e.g. 4';

  @override
  String get excursionDetailsOffersLanguageAny => 'Any language';

  @override
  String get excursionDetailsOffersLanguageSearchHint => 'Language or code';

  @override
  String get excursionDetailsOffersLanguageNoResults => 'Language not found';

  @override
  String get excursionDetailsOffersApplyFilters => 'Apply filters';

  @override
  String get excursionDetailsMapPreview => 'Route meeting point';

  @override
  String get excursionDetailsItinerary => 'Itinerary';

  @override
  String get excursionDetailsMeetingPoint => 'Meeting point';

  @override
  String get excursionDetailsTotal => 'Total';

  @override
  String get excursionDetailsBook => 'Book';

  @override
  String get excursionDetailsBookingSeatCheckNote =>
      'Exact seats for your group are checked on the booking screen.';

  @override
  String get excursionDetailsCheckingSchedule => 'Checking available times...';

  @override
  String get excursionDetailsNoAvailableSlots =>
      'This guide has no available time slots for this excursion yet.';

  @override
  String get excursionDetailsEditOffer => 'Edit offer';

  @override
  String get excursionDetailsLoadFailed => 'Failed to load excursion';

  @override
  String get excursionDetailsBookingComingSoon =>
      'Excursion booking will be available soon.';

  @override
  String get excursionDetailsGuideChatComingSoon =>
      'Guide chat will be available soon.';

  @override
  String get excursionBookingTitle => 'Booking Excursion';

  @override
  String get excursionBookingSchedule => 'Schedule';

  @override
  String get excursionBookingChange => 'Change';

  @override
  String get excursionBookingDate => 'Date';

  @override
  String get excursionBookingTimeSlot => 'Time Slot';

  @override
  String get excursionBookingTravelers => 'Travelers';

  @override
  String get excursionBookingAdults => 'Adults';

  @override
  String get excursionBookingChildren => 'Children';

  @override
  String get excursionBookingSummary => 'Summary';

  @override
  String excursionBookingAdultSummary(Object count, Object price) {
    return 'Adult ($count x $price)';
  }

  @override
  String excursionBookingChildrenSummary(Object count, Object price) {
    return 'Children ($count x $price)';
  }

  @override
  String get excursionBookingServiceFeeSummary => 'Service fee (5%)';

  @override
  String get excursionBookingTotalPrice => 'Total Price';

  @override
  String get excursionBookingConfirmReservation => 'Confirm booking';

  @override
  String excursionBookingPaymentPendingNote(Object amount) {
    return 'No payment is charged now. Online payment will appear when it is connected. Total: $amount';
  }

  @override
  String get excursionBookingSubmitted =>
      'Booking is confirmed. Online payment will be connected soon.';

  @override
  String get excursionBookingAlreadyBookedTitle =>
      'You already booked this time';

  @override
  String get excursionBookingAlreadyBookedMessage =>
      'You can change the number of guests in My excursions.';

  @override
  String get excursionBookingOpenMyExcursions => 'Open My excursions';

  @override
  String get excursionBookingLoadFailed => 'Failed to load excursion booking';

  @override
  String get excursionBookingPerPerson => '/ person';

  @override
  String get excursionBookingSelectSlot => 'Select an available time';

  @override
  String excursionBookingSelectedSlotUnavailable(Object count) {
    return 'The selected time is no longer available for $count guests. Choose another time.';
  }

  @override
  String get excursionBookingScheduleLoadFailed =>
      'Failed to load available times';

  @override
  String get excursionBookingNoSlots =>
      'The guide has not added available times for this offer yet.';

  @override
  String excursionBookingSeatsLeft(Object count) {
    return '$count seats left';
  }

  @override
  String get excursionDetailsNoDescription =>
      'Your guide will share the detailed description soon.';

  @override
  String excursionDetailsRouteStopsCount(Object count) {
    return '$count stops';
  }

  @override
  String excursionDetailsTravelFromPrevious(Object minutes) {
    return '$minutes min from previous stop';
  }

  @override
  String get createExcursionTitle => 'Create Excursion';

  @override
  String get createExcursionEditTitle => 'Edit Offer';

  @override
  String get createExcursionSubmit => 'Submit for review';

  @override
  String get createExcursionSaveDraft => 'Save draft';

  @override
  String get createExcursionSaveChanges => 'Save';

  @override
  String get createExcursionSuccess => 'Excursion sent for review';

  @override
  String get createExcursionDraftSaved => 'Draft saved';

  @override
  String get createExcursionUpdateSuccess => 'Offer updated successfully';

  @override
  String get createExcursionFailed => 'Failed to create excursion';

  @override
  String get createExcursionUpdateFailed => 'Failed to update offer';

  @override
  String get createExcursionCoverSection => 'Excursion Cover';

  @override
  String get createExcursionCoverUploadTitle => 'Upload Excursion Image';

  @override
  String get createExcursionCoverChangeAction => 'Change Excursion Image';

  @override
  String get createExcursionCoverUploadHint =>
      'JPG, PNG or WEBP. If you selected an attraction, its photo will be used unless you upload your own.';

  @override
  String get createExcursionSelectedLandmark => 'Attraction';

  @override
  String get createExcursionLandmarkNameLabel => 'Landmark';

  @override
  String get createExcursionLandmarkNameHint => 'e.g. Medeu';

  @override
  String get createExcursionLandmarkValidation => 'Choose an attraction';

  @override
  String get createExcursionCountryValidation => 'Select a country first';

  @override
  String get createExcursionSelectCountryFirst => 'Select a country first';

  @override
  String get createExcursionManualLocationHint =>
      'You can enter a custom location or choose an attraction from this country.';

  @override
  String get createExcursionLocationLockedByAttraction =>
      'This location comes from the attraction catalog. Change the attraction to edit it.';

  @override
  String get createExcursionAttractionCatalogHint =>
      'Attraction catalog for the selected country';

  @override
  String get createExcursionAttractionCatalogSource =>
      'From the attraction catalog';

  @override
  String get createExcursionSingleAttractionMode => 'Single attraction';

  @override
  String get createExcursionCombinedRouteMode => 'Combined route';

  @override
  String createExcursionCombinedRouteMinStopsValidation(Object count) {
    return 'Add at least $count attraction stops';
  }

  @override
  String createExcursionCombinedRouteMaxStopsValidation(Object count) {
    return 'Add no more than $count attraction stops';
  }

  @override
  String get createExcursionDuplicateRouteStopValidation =>
      'This attraction is already in the route.';

  @override
  String get excursionSelectLocationTitle => 'Select Attraction';

  @override
  String get excursionSelectLocationCountrySection => 'Select Country';

  @override
  String get excursionSelectLocationCountrySearchHint => 'Countries';

  @override
  String get excursionCountryKazakhstan => 'Kazakhstan';

  @override
  String get excursionCountryFrance => 'France';

  @override
  String get excursionCountryJapan => 'Japan';

  @override
  String get excursionCountryItaly => 'Italy';

  @override
  String get excursionSelectLocationAttractionSection => 'Select Attraction';

  @override
  String get excursionSelectLocationAttractionSearchHint => 'Attractions';

  @override
  String get excursionSelectLocationSelected => 'Selected';

  @override
  String excursionSelectLocationPageCaption(Object current, Object total) {
    return 'PAGE $current OF $total';
  }

  @override
  String get createExcursionCategorization => 'Travel Categorization';

  @override
  String get createExcursionCategoryAdventure => 'Adventure';

  @override
  String get createExcursionCategoryCultural => 'Cultural';

  @override
  String get createExcursionCategoryCulinary => 'Culinary';

  @override
  String get createExcursionCategoryWellness => 'Wellness';

  @override
  String get createExcursionDetailedItinerary => 'Detailed Itinerary';

  @override
  String get createExcursionAddTimeSlot => 'Add Time Slot';

  @override
  String get createExcursionEditTimeSlot => 'Edit Time Slot';

  @override
  String get createExcursionItineraryEmpty =>
      'Add at least two route points. They will be shown to tourists in the excursion details.';

  @override
  String get createExcursionAutosaveHint =>
      'Progress is saved locally while you create the offer';

  @override
  String get createExcursionAutosaveRestored => 'Local draft restored';

  @override
  String get createExcursionDiscardTitle => 'Leave without saving?';

  @override
  String get createExcursionDiscardDescription =>
      'Your excursion draft data will be lost. The form will open empty next time.';

  @override
  String get createExcursionDiscardConfirm => 'Leave and discard';

  @override
  String get createExcursionModeSwitchTitle => 'Switch route type?';

  @override
  String get createExcursionModeSwitchDescription =>
      'Data from the current route type will be cleared. Other excursion details will stay in place.';

  @override
  String get createExcursionModeSwitchCancel => 'Stay here';

  @override
  String get createExcursionModeSwitchConfirm => 'Switch and clear';

  @override
  String get createExcursionItineraryValidation =>
      'Fill in the route point time, title, and description';

  @override
  String createExcursionItineraryMinSlotsValidation(Object count) {
    return 'Add at least $count route points';
  }

  @override
  String createExcursionItineraryDescriptionMinLengthValidation(Object count) {
    return 'Route point description must be at least $count characters';
  }

  @override
  String get createExcursionStartOffsetValidation =>
      'Enter the route point start time';

  @override
  String get createExcursionItineraryTitleValidation =>
      'Route point title must be at least 2 characters';

  @override
  String createExcursionOffsetMinutesShort(Object minutes) {
    return '+${minutes}m';
  }

  @override
  String createExcursionOffsetHoursShort(Object hours) {
    return '+${hours}h';
  }

  @override
  String createExcursionOffsetHoursMinutesShort(Object hours, Object minutes) {
    return '+${hours}h ${minutes}m';
  }

  @override
  String get createExcursionDurationLabel => 'Duration';

  @override
  String get createExcursionDurationHint => 'e.g. 4 hours';

  @override
  String get createExcursionDurationUnitLabel => 'Unit';

  @override
  String get createExcursionDurationUnitMinutes => 'Minutes';

  @override
  String get createExcursionDurationUnitHours => 'Hours';

  @override
  String get createExcursionDurationUnitDays => 'Days';

  @override
  String get createExcursionDurationValidation =>
      'Enter a duration of at least 15 minutes';

  @override
  String get createExcursionMaxGroupSizeLabel => 'Max Group Size';

  @override
  String get createExcursionMaxGroupSizeHint => 'e.g. 12';

  @override
  String get createExcursionGroupSizeValidation =>
      'Enter a group size from 1 to 100';

  @override
  String get createExcursionLanguagesLabel => 'Languages Spoken';

  @override
  String get createExcursionLanguagesHint => 'English, French, Japanese...';

  @override
  String get createExcursionLanguagesValidation =>
      'Add at least one excursion language';

  @override
  String createExcursionLanguagesPickerHint(Object count) {
    return 'Select up to $count languages';
  }

  @override
  String get createExcursionLanguagesSearchHint => 'Language or code';

  @override
  String get createExcursionLanguagesNoResults => 'Language not found';

  @override
  String createExcursionLanguagesLimitValidation(Object count) {
    return 'You can select up to $count languages';
  }

  @override
  String get createExcursionVisibilityTitle => 'Excursion Visibility';

  @override
  String get createExcursionVisibilityPublicDescription =>
      'Visible to everyone in the Inflap marketplace.';

  @override
  String get createExcursionVisibilityUnlistedDescription =>
      'Only users with the direct URL can view and book this excursion.';

  @override
  String get createExcursionMeetingPointHint =>
      'Enter meeting address or landmark...';

  @override
  String get createExcursionSoulTitle => 'Soul of the Journey';

  @override
  String get createExcursionNameLabel => 'Excursion Title';

  @override
  String get createExcursionNameHint => 'e.g. Almaty Mountain Escape';

  @override
  String get createExcursionSummaryLabel => 'Short Summary';

  @override
  String get createExcursionSummaryHint => 'A concise promise for travelers';

  @override
  String get createExcursionSummaryValidation =>
      'Summary must be at least 3 characters';

  @override
  String get createExcursionSoulHint =>
      'Describe the soul of this journey, hidden details, and the feeling of being there...';

  @override
  String get createExcursionDescriptionValidation =>
      'Description must be at least 20 characters';

  @override
  String get createExcursionInvestmentTitle => 'Investment Per Person';

  @override
  String get createExcursionCurrencyValidation => 'Enter a currency code';

  @override
  String get createCurrencyKzt => 'tenge';

  @override
  String get createCurrencyUsd => 'US dollar';

  @override
  String get createCurrencyEur => 'euro';

  @override
  String get createCurrencyRub => 'ruble';

  @override
  String get createCurrencyGbp => 'pound sterling';

  @override
  String get createExcursionIncludedItemsLabel => 'Included Items';

  @override
  String get createExcursionIncludedItemsHint =>
      'Comma-separated: Private SUV, picnic, tickets';

  @override
  String get createExcursionIncludedItemsEmpty =>
      'Add exact items such as transport, meals, entrance tickets, or gear';

  @override
  String get createExcursionIncludedItemsEditorTitle => 'What is included';

  @override
  String get createExcursionIncludedItemsAdd => 'Add item';

  @override
  String get createExcursionIncludedItemsRemove => 'Remove item';

  @override
  String get createExcursionIncludedItemsTypeLabel => 'Type';

  @override
  String get createExcursionIncludedItemsValueLabel =>
      'What exactly is included';

  @override
  String get createExcursionIncludedItemsValueHint =>
      'e.g. Private SUV transfer';

  @override
  String get createExcursionIncludedItemsValidation =>
      'Fill in every included item or remove empty rows';

  @override
  String get createExcursionIncludedTypeTransport => 'Transport';

  @override
  String get createExcursionIncludedTypeFood => 'Meals';

  @override
  String get createExcursionIncludedTypeTickets => 'Tickets';

  @override
  String get createExcursionIncludedTypeEquipment => 'Equipment';

  @override
  String get createExcursionIncludedTypeGuide => 'Guide';

  @override
  String get createExcursionIncludedTypePhoto => 'Photo';

  @override
  String get createExcursionIncludedTypeOther => 'Other';

  @override
  String get createExcursionStartOffsetLabel => 'Start after, min';

  @override
  String get createExcursionSlotDurationLabel => 'Duration, min';

  @override
  String get createExcursionItineraryTitleLabel => 'Title';

  @override
  String get createExcursionItineraryTitleHint => 'e.g. Mountain Ascent';

  @override
  String get createExcursionItineraryDescriptionLabel => 'Description';

  @override
  String get createExcursionItineraryDescriptionHint =>
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
  String get createActivityDiscardTitle => 'Discard this activity?';

  @override
  String get createActivityDiscardDescription =>
      'Your draft changes will be lost if you leave now.';

  @override
  String get createActivityDiscardConfirm => 'Discard';

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
  String get createSubcategoryLabel => 'Subcategory';

  @override
  String get createSubcategoryHint => 'Select a subcategory';

  @override
  String get createSubcategoryPickerTitle => 'Choose Subcategory';

  @override
  String get createSubcategoryApply => 'Apply';

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
      'Visible to everyone on Inflap';

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
  String get createVisibilityPasswordAsciiValidation =>
      'Use only English letters, numbers, and symbols';

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
  String get createAllowParticipantInvitesLabel =>
      'Allow participants to invite friends';

  @override
  String get createAllowParticipantInvitesHint =>
      'The activity author can always invite their friends. Other users can invite only their own friends when this option is enabled.';

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
  String get createMapLinkInvalidError =>
      'We couldn\'t detect coordinates from this link. Choose a point on our map or paste a link with coordinates from another map.';

  @override
  String get createMapLinkResolvingError =>
      'Detecting coordinates from this link. Please wait a few seconds.';

  @override
  String get createMapLinkRequiredError =>
      'Add a map link or choose a point on our map.';

  @override
  String get createMapEarlyStageNotice =>
      'Our in-app map is still early-stage: paste a link from another map or place a point on our map for now. Soon we\'ll improve the map so you can choose the meeting point here without switching to other map apps.';

  @override
  String get createOfflineSection => 'VENUE';

  @override
  String get createLocationPreviewHint =>
      'Add a city or address so participants know where to meet';

  @override
  String get createAuthorLocationMismatchHint =>
      'Meeting city differs from your current location. Keep it if this activity is planned for another place.';

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
      'Meeting address can be changed until 1 hour before the activity starts';

  @override
  String get editPriceRestrictionHint =>
      'Price cannot be changed if other participants have already joined';

  @override
  String get myActivitiesTitle => 'My Activities';

  @override
  String get myStoriesTitle => 'My Posts';

  @override
  String get myStoryArchiveTitle => 'My Stories';

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
  String get myActivitiesRetryButton => 'Try Again';

  @override
  String get myActivitiesPriceNoteFree => 'no fee';

  @override
  String get myExcursionsTitle => 'My Excursions';

  @override
  String get myExcursionsSearchHint => 'Excursions, guides, and cities';

  @override
  String get myExcursionsFilterTitle => 'Excursion filters';

  @override
  String get myExcursionsReviewSuccess => 'Review published';

  @override
  String get myExcursionsSortLabel => 'Sort';

  @override
  String get myExcursionsSortDate => 'By date';

  @override
  String get myExcursionsSortPrice => 'By price';

  @override
  String get myExcursionsLoadFailed => 'Failed to load your excursions';

  @override
  String get myExcursionsBookedEmpty => 'You don\'t have booked excursions yet';

  @override
  String get myExcursionsVisitedEmpty =>
      'You haven\'t visited any excursions yet';

  @override
  String get myExcursionsBookedEmptyHint =>
      'Booked excursions will appear here';

  @override
  String get myExcursionsVisitedEmptyHint =>
      'After a visit, you can leave a review here';

  @override
  String get myExcursionsBookedTab => 'Booked';

  @override
  String get myExcursionsVisitedTab => 'Visited';

  @override
  String get myExcursionsGuideFallback => 'Inflap guide';

  @override
  String get myExcursionsUntitled => 'Excursion';

  @override
  String myExcursionsGuideLine(Object guide) {
    return 'Guide: $guide';
  }

  @override
  String myExcursionsGuests(Object count) {
    return 'Guests: $count';
  }

  @override
  String get myExcursionsReviewButton => 'Rate';

  @override
  String get myExcursionsReviewed => 'Reviewed';

  @override
  String get myExcursionsEditGuestsButton => 'Edit guests';

  @override
  String get myExcursionsEditGuestsTitle => 'Edit guests';

  @override
  String get myExcursionsEditGuestsHint =>
      'We will check available seats and update the booking without creating another one.';

  @override
  String get myExcursionsUpdateGuestsSuccess => 'Guest count updated';

  @override
  String get myExcursionsUpdateGuestsFailed =>
      'Failed to update guest count. Check available seats and try again.';

  @override
  String myExcursionsGuestsAdditionalCharge(Object amount) {
    return 'Additional charge: $amount';
  }

  @override
  String myExcursionsGuestsRefundDue(Object amount) {
    return 'Refund due: $amount';
  }

  @override
  String get myExcursionsGuestsNoPaymentChange => 'Price will not change';

  @override
  String get myExcursionsGuestsPaymentQuoteHint =>
      'The estimate is calculated on the server. Real charges or refunds will be connected through the payment service.';

  @override
  String get myExcursionsGuestsQuoteLoading => 'Calculating price change...';

  @override
  String get myExcursionsGuestsQuoteFailed =>
      'Could not calculate the price change. Check available seats and try again.';

  @override
  String get myExcursionsPayAndSaveGuests => 'Pay and save';

  @override
  String get myExcursionsRefundAndSaveGuests => 'Refund and save';

  @override
  String get myExcursionsCancelBookingButton => 'Cancel booking';

  @override
  String get myExcursionsCancelBookingTitle => 'Cancel booking?';

  @override
  String get myExcursionsCancelBookingHint =>
      'We will cancel your place and show the guide that the booking was cancelled by you.';

  @override
  String get myExcursionsCancelQuoteLoading => 'Calculating refund terms...';

  @override
  String get myExcursionsCancelQuoteFailed =>
      'Could not calculate refund terms. Try again.';

  @override
  String myExcursionsCancelBookingRefund(Object amount, int percent) {
    return 'Refund: $amount ($percent%)';
  }

  @override
  String get myExcursionsCancelBookingNoRefund => 'Refund is not available';

  @override
  String get myExcursionsCancelBookingRefundHint =>
      'The server will fix the final refund amount. Real payment refund will be connected through the payment service.';

  @override
  String get myExcursionsCancelPolicyTitle => 'Cancellation policy';

  @override
  String get myExcursionsCancelPolicyFull => '24+ hours before start: 100%';

  @override
  String get myExcursionsCancelPolicySeventyFive =>
      '12-24 hours before start: 75%';

  @override
  String get myExcursionsCancelPolicyHalf => '6-12 hours before start: 50%';

  @override
  String get myExcursionsCancelPolicyQuarter => '2-6 hours before start: 25%';

  @override
  String get myExcursionsCancelPolicyZero =>
      'Less than 2 hours before start: 0%';

  @override
  String get myExcursionsCancelBookingReasonLabel => 'Reason (optional)';

  @override
  String get myExcursionsCancelBookingReasonPlaceholder =>
      'For example: plans changed';

  @override
  String get myExcursionsCancelBookingConfirm => 'Cancel booking';

  @override
  String get myExcursionsCancelBookingSuccess => 'Booking cancelled';

  @override
  String get myExcursionsCancelBookingFailed => 'Failed to cancel booking';

  @override
  String myExcursionsCancelledWithRefund(Object amount, int percent) {
    return 'Cancelled. Refund: $amount ($percent%)';
  }

  @override
  String get myExcursionsCancelledWithoutRefund => 'Cancelled without refund';

  @override
  String get myExcursionsFilterStatus => 'Status';

  @override
  String get myExcursionsStatusRequested => 'Booked';

  @override
  String get myExcursionsFilterReview => 'Reviews';

  @override
  String get myExcursionsFilterReviewAll => 'All';

  @override
  String get myExcursionsFilterUnreviewed => 'Without review';

  @override
  String get myExcursionsFilterReviewed => 'Reviewed';

  @override
  String get myExcursionsReviewTitle => 'Rate the excursion';

  @override
  String get myExcursionsReviewCommentError => 'Write a short review';

  @override
  String get myExcursionsReviewFailed => 'Failed to publish review';

  @override
  String get myExcursionsReviewDeleteFailed => 'Failed to delete review';

  @override
  String get myExcursionsReviewRating => 'Rating';

  @override
  String get myExcursionsReviewHint =>
      'What did you like, and what could be better?';

  @override
  String get myExcursionsExcursionReviewSectionTitle => 'Excursion review';

  @override
  String get myExcursionsExcursionReviewSectionSubtitle =>
      'Rate the route, organization, and overall experience.';

  @override
  String get myExcursionsExcursionReviewOptional =>
      'Turn this off if you only want to rate the guide.';

  @override
  String get myExcursionsGuideReviewSectionTitle => 'Guide review';

  @override
  String get myExcursionsGuideReviewSectionSubtitle =>
      'Optionally rate the guide separately for future travelers.';

  @override
  String get myExcursionsGuideReviewRating => 'Guide rating';

  @override
  String get myExcursionsGuideReviewHint =>
      'How was the guide\'s communication, care, and storytelling?';

  @override
  String get myExcursionsGuideReviewOptional =>
      'Optional, but it helps the guide build a trusted profile.';

  @override
  String get myExcursionsReviewSelectOneError =>
      'Choose at least one review to publish';

  @override
  String get myExcursionsReviewDeleteExcursion => 'Delete excursion review';

  @override
  String get myExcursionsReviewDeleteGuide => 'Delete guide review';

  @override
  String get myExcursionsReviewPublish => 'Publish';

  @override
  String get excursionReviewActionsTitle => 'Review actions';

  @override
  String get excursionReviewEditAction => 'Edit review';

  @override
  String get excursionReviewDeleteAction => 'Delete review';

  @override
  String get excursionReviewEditTitle => 'Edit review';

  @override
  String get excursionReviewEditSave => 'Save review';

  @override
  String get excursionReviewUpdated => 'Review updated';

  @override
  String get excursionReviewDeleted => 'Review deleted';

  @override
  String get guideDashboardTitle => 'Guide Dashboard';

  @override
  String get guideDashboardReviewsTitle => 'Reviews';

  @override
  String get guideDashboardExcursionReviewsTab => 'Excursions';

  @override
  String get guideDashboardDirectGuideReviewsTab => 'Guide';

  @override
  String get guideDashboardOffersStat => 'Total offers';

  @override
  String get guideDashboardBookingsStat => 'Bookings';

  @override
  String get guideDashboardRevenueStat => 'Revenue';

  @override
  String get guideDashboardRatingStat => 'Rating';

  @override
  String get guideDashboardSearchHint => 'Offers, guests, cities, and dates';

  @override
  String get guideDashboardOffersTab => 'Offers';

  @override
  String get guideDashboardBookingsTab => 'Booked';

  @override
  String get guideDashboardCompletedTab => 'Completed';

  @override
  String get guideDashboardActiveTab => 'Active';

  @override
  String get guideDashboardDraftTab => 'Drafts';

  @override
  String get guideDashboardArchiveTab => 'Archive';

  @override
  String get guideDashboardReviewTab => 'Review';

  @override
  String get guideDashboardRejectedTab => 'Rejected';

  @override
  String get guideDashboardCancelledTab => 'Cancelled';

  @override
  String get guideDashboardLoadFailed => 'Failed to load guide dashboard';

  @override
  String get guideDashboardOffersEmpty => 'No active offers yet';

  @override
  String get guideDashboardOffersEmptyHint =>
      'Publish your first excursion offer so travelers can book it.';

  @override
  String get guideDashboardBookingsEmpty => 'No upcoming bookings';

  @override
  String get guideDashboardBookingsEmptyHint =>
      'New client bookings will appear here with date, guests, and payout amount.';

  @override
  String get guideDashboardCompletedEmpty => 'No completed excursions yet';

  @override
  String get guideDashboardCompletedEmptyHint =>
      'Finished excursions move here after their scheduled date.';

  @override
  String get guideDashboardDraftEmpty => 'No draft offers';

  @override
  String get guideDashboardDraftEmptyHint =>
      'Saved drafts stay private until you send them for review.';

  @override
  String get guideDashboardReviewEmpty => 'Nothing is under review';

  @override
  String get guideDashboardReviewEmptyHint =>
      'Offers waiting for moderation or publication will appear here.';

  @override
  String get guideDashboardDirectGuideReviewsEmpty =>
      'Direct guide reviews will appear here after travelers rate you separately.';

  @override
  String get guideDashboardArchiveEmpty => 'Archive is empty';

  @override
  String get guideDashboardArchiveEmptyHint =>
      'Archive offers that are temporarily unavailable to remove them from active lists while keeping edit and publish access.';

  @override
  String get guideDashboardRejectedEmpty => 'No rejected offers';

  @override
  String get guideDashboardRejectedEmptyHint =>
      'Offers declined during moderation will appear here with edit access.';

  @override
  String get guideDashboardCancelledEmpty => 'No cancelled bookings';

  @override
  String get guideDashboardCancelledEmptyHint =>
      'Cancelled client bookings are kept here for history and guest follow-up.';

  @override
  String get guideDashboardCreateOffer => 'Create offer';

  @override
  String get guideDashboardEditOffer => 'Edit offer';

  @override
  String get guideDashboardArchiveOffer => 'Archive';

  @override
  String get guideDashboardPublishOffer => 'Publish';

  @override
  String get guideDashboardSubmitOffer => 'Submit for review';

  @override
  String get guideDashboardDeleteDraftOffer => 'Delete draft';

  @override
  String get guideDashboardDeleteDraftTitle => 'Delete draft offer?';

  @override
  String get guideDashboardDeleteDraftMessage =>
      'This draft will be permanently removed. This action cannot be undone.';

  @override
  String get guideDashboardDeleteDraftConfirm => 'Delete draft';

  @override
  String get guideDashboardDeleteDraftSuccess => 'Draft offer deleted';

  @override
  String get guideDashboardDeleteDraftFailed => 'Failed to delete draft offer';

  @override
  String get guideDashboardArchiveFailed => 'Failed to move offer to archive';

  @override
  String get guideDashboardPublishFailed => 'Failed to publish offer';

  @override
  String get guideDashboardSubmitFailed => 'Failed to submit offer for review';

  @override
  String get guideDashboardViewBooking => 'View booking';

  @override
  String get guideDashboardShowAttendanceQr => 'Attendance QR';

  @override
  String get guideDashboardAttendanceParticipants => 'Participants';

  @override
  String get guideDashboardAttendanceCheckedIn => 'Checked in';

  @override
  String get guideDashboardAttendanceWaiting => 'Waiting for check-in';

  @override
  String get guideDashboardViewDetails => 'View details';

  @override
  String get guideDashboardCancelExcursion => 'Cancel excursion';

  @override
  String get guideDashboardCancelTitle => 'Cancel this excursion?';

  @override
  String get guideDashboardCancelDescription =>
      'We will cancel this slot for guests and show the amount that must be refunded for affected bookings.';

  @override
  String get guideDashboardCancelReasonLabel => 'Cancellation reason';

  @override
  String get guideDashboardCancelReasonPlaceholder =>
      'For example: the guide is sick or weather makes the route unsafe';

  @override
  String get guideDashboardCancelReasonRequired =>
      'Enter a cancellation reason';

  @override
  String get guideDashboardCancelConfirm => 'Confirm cancellation';

  @override
  String get guideDashboardCancelSuccess => 'Excursion cancelled';

  @override
  String get guideDashboardCancelFailed => 'Failed to cancel excursion';

  @override
  String get guideDashboardCancelNoSlot =>
      'This booking does not have a schedule slot to cancel';

  @override
  String guideDashboardRefundAmount(Object amount) {
    return 'Refund to guests: $amount';
  }

  @override
  String get guideDashboardCancelledByTourist => 'Cancelled by tourist';

  @override
  String get guideDashboardCancelledByGuide => 'Cancelled by guide';

  @override
  String guideDashboardCancellationReason(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String get guideDashboardBookingSheetTitle => 'Booking details';

  @override
  String get guideDashboardBookingAuthorsTitle => 'Booking authors';

  @override
  String get guideDashboardAdults => 'Adults';

  @override
  String get guideDashboardChildren => 'Children';

  @override
  String get guideDashboardTotalGuests => 'Total guests';

  @override
  String guideDashboardGuestBreakdown(
    Object adults,
    Object children,
    Object total,
  ) {
    return 'Adults: $adults · Children: $children · Total: $total';
  }

  @override
  String get guideDashboardStatusActive => 'Active';

  @override
  String get guideDashboardStatusDraft => 'Draft';

  @override
  String get guideDashboardStatusArchived => 'Archived';

  @override
  String get guideDashboardStatusReview => 'Under review';

  @override
  String get guideDashboardStatusRejected => 'Rejected';

  @override
  String get guideDashboardStatusBooked => 'Booked';

  @override
  String get guideDashboardStatusCompleted => 'Completed';

  @override
  String get guideDashboardStatusCancelled => 'Cancelled';

  @override
  String get guideDashboardFlexibleGroup => 'Flexible group';

  @override
  String guideDashboardMaxGuests(Object count) {
    return 'Up to $count guests';
  }

  @override
  String guideDashboardBookingCount(Object count) {
    return '$count bookings';
  }

  @override
  String get excursionReviewsTitle => 'Reviews after excursions';

  @override
  String get excursionReviewsEmpty =>
      'There are no reviews for this excursion yet';

  @override
  String excursionReviewViaGuide(Object guide) {
    return 'Via guide: $guide';
  }

  @override
  String get excursionReviewSourceAttractionBadge =>
      'Review based on a visited excursion';

  @override
  String get activityReviewsSectionTitle => 'Reviews';

  @override
  String get activityReviewsTitle => 'Activity reviews';

  @override
  String get activityOrganizerReviewsTitle => 'Organizer reviews';

  @override
  String get activityReviewsEmpty =>
      'There are no reviews for this activity yet';

  @override
  String get activityReviewsLoadFailed => 'Could not load activity reviews';

  @override
  String get activityReviewSheetTitle => 'Rate the activity';

  @override
  String get activityReviewActivityLabel => 'Activity';

  @override
  String get activityReviewOrganizerLabel => 'Organizer';

  @override
  String get activityReviewWriteButton => 'Leave review';

  @override
  String get activityReviewEditButton => 'Edit review';

  @override
  String get activityReviewUnavailable =>
      'Reviews are available only to checked-in participants after the activity is completed.';

  @override
  String get activityReviewSaved => 'Review saved';

  @override
  String get activityReviewSaveFailed => 'Could not save review';

  @override
  String get activityReviewPublishConfirmTitle => 'Publish review?';

  @override
  String get activityReviewPublishConfirmDescription =>
      'After publishing, your activity and organizer ratings will be visible in reviews.';

  @override
  String get activityReviewPublishConfirmButton => 'Publish review';

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
  String get activitiesSearchHint => 'Activities, hosts, or cities';

  @override
  String get activitiesFiltersTitle => 'Filters';

  @override
  String get activitiesFilterCountrySection => 'Country';

  @override
  String get activitiesFilterCountryAll => 'All countries';

  @override
  String get activitiesFilterCountrySearchHint => 'Country, code, or phone';

  @override
  String get activitiesFilterCountryNoResults => 'Country not found';

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
  String get activitiesNearbyTitle => 'Activities nearby';

  @override
  String get activitiesNearbyMapEmpty =>
      'Activities do not have meeting points yet';

  @override
  String get activitiesFilteredEmptyTitle =>
      'No activities match these filters';

  @override
  String get activitiesFilteredEmptySubtitle =>
      'Try widening the category, date range, pricing filters, or choose another city';

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
  String get qrScannerInvalidCode => 'This is not an Inflap activity QR';

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
  String get storiesDiscoverTitle => 'Posts';

  @override
  String get storiesNavLabel => 'Posts';

  @override
  String get storiesActivitiesNavLabel => 'Activities';

  @override
  String get storySearchHint => 'Posts, authors, or places';

  @override
  String get storySearchCompactHint => 'Posts';

  @override
  String get storyFiltersTitle => 'Filters';

  @override
  String get storyFiltersActiveSummary => 'Selected filters';

  @override
  String get storyFilterFormat => 'Material type';

  @override
  String get storyFilterCategory => 'Theme';

  @override
  String get storyFilterCountry => 'Country';

  @override
  String get storyFilterCountryAll => 'All countries';

  @override
  String get storyFilterCountrySearchHint => 'Country, code, or phone';

  @override
  String get storyFilterCountryNoResults => 'Country not found';

  @override
  String get storyFilterAll => 'All';

  @override
  String storiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
      zero: '0 posts',
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
  String get storyCreateCta => 'Share a post';

  @override
  String get storyCreateFirst => 'Create the first post';

  @override
  String get storyEmptyTitle => 'No posts yet';

  @override
  String get storyEmptySubtitle =>
      'Be the first to publish a travel note, local guide, or visual essay.';

  @override
  String get storyEmptyAuthenticatedSubtitle =>
      'Create a post, article, guide, or visual essay to start the feed.';

  @override
  String get storyFilteredEmptyTitle => 'No posts match your filters';

  @override
  String get storyFilteredEmptySubtitle =>
      'Try a different search, country, city, or category.';

  @override
  String get storyResetFiltersAction => 'Clear';

  @override
  String get storyLoginCreateAction => 'Log in to create';

  @override
  String get myStoriesDraftsTab => 'Drafts';

  @override
  String get myStoriesPendingReviewTab => 'In review';

  @override
  String get myStoriesPublishedTab => 'Published';

  @override
  String get myStoriesArchivedTab => 'Archived';

  @override
  String get myStoriesDraftEmptyTitle => 'No drafts yet';

  @override
  String get myStoriesDraftEmptySubtitle =>
      'Save ideas as drafts before publishing them to the posts feed.';

  @override
  String get myStoriesPendingReviewEmptyTitle => 'No posts in review';

  @override
  String get myStoriesPendingReviewEmptySubtitle =>
      'Posts waiting for moderator review will appear here.';

  @override
  String get myStoriesPublishedEmptyTitle => 'No published posts yet';

  @override
  String get myStoriesPublishedEmptySubtitle =>
      'Published posts, guides, articles, and visual essays will appear here.';

  @override
  String get myStoriesArchivedEmptyTitle => 'No archived posts yet';

  @override
  String get myStoriesArchivedEmptySubtitle =>
      'Archived posts are kept here for history and reuse.';

  @override
  String get myStoriesCreateDraftAction => 'Create a draft';

  @override
  String get storyArchiveActiveTab => 'Active';

  @override
  String get storyArchiveArchiveTab => 'Archive';

  @override
  String get storyArchiveActiveSubtitle =>
      'These are your stories that are still visible to other users.';

  @override
  String get storyArchiveActiveEmptyTitle => 'No active stories yet';

  @override
  String get storyArchiveActiveEmptySubtitle =>
      'Capture a photo or video story to keep it here for 24 hours.';

  @override
  String get storyArchiveActiveUntilPrefix => 'Active until';

  @override
  String get storyArchiveSubtitle =>
      'Stories live for 24 hours, then stay here for you.';

  @override
  String get storyArchiveEmptyTitle => 'No archived stories yet';

  @override
  String get storyArchiveEmptySubtitle =>
      'Your camera stories will appear here after 24 hours.';

  @override
  String get storyArchiveLoadFailedTitle => 'Could not load stories';

  @override
  String get storyArchiveLoadFailedMessage =>
      'Check the connection and try again.';

  @override
  String get storyArchiveRetryAction => 'Try again';

  @override
  String get storyArchiveLoadMoreAction => 'Load more';

  @override
  String get storyArchiveExpiredPrefix => 'Archived';

  @override
  String get storyStateSeenLabel => 'Seen';

  @override
  String get storyStateExpiredLabel => 'Expired';

  @override
  String get storyStatePendingLabel => 'Pending review';

  @override
  String get storyStateHiddenLabel => 'Hidden';

  @override
  String get storyLoadFailed => 'Failed to load posts';

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
  String get storyFormatStory => 'Post';

  @override
  String get storyFormatGuide => 'Guide';

  @override
  String get storyFormatPhotoEssay => 'Photo Essay';

  @override
  String get storyFormatArticle => 'Article';

  @override
  String get storyFormatCulinary => 'Culinary';

  @override
  String get storyDetailsTitle => 'Post details';

  @override
  String get storyLinkCopied => 'Post link copied';

  @override
  String get storyShareFailed =>
      'Unable to open the share sheet. Please try again.';

  @override
  String get storyReportAction => 'Report';

  @override
  String get storyReportSending => 'Sending...';

  @override
  String get storyReportTitle => 'Report post';

  @override
  String get storyReportSubtitle =>
      'Tell us what is wrong. Reports help moderators keep travel content safe and useful.';

  @override
  String get storyReportDetailsLabel => 'Details';

  @override
  String get storyReportDetailsHint => 'Add context for moderators';

  @override
  String get storyReportSubmitAction => 'Submit report';

  @override
  String get storyReportSubmitted => 'Thanks. We sent this post to moderation.';

  @override
  String get storyReportAutoHidden =>
      'Thanks. This post is hidden while moderators review it.';

  @override
  String get storyReportReasonSpam => 'Spam or misleading';

  @override
  String get storyReportReasonHarassment => 'Harassment';

  @override
  String get storyReportReasonHate => 'Hate or discrimination';

  @override
  String get storyReportReasonSexualContent => 'Sexual content';

  @override
  String get storyReportReasonViolence => 'Violence or graphic content';

  @override
  String get storyReportReasonMisinformation => 'Misinformation';

  @override
  String get storyReportReasonIllegal => 'Illegal activity';

  @override
  String get storyReportReasonOther => 'Other';

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
  String get storyLikeActionFailed =>
      'Could not update the like. Please try again.';

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
  String get storyRelatedTitle => 'Related posts';

  @override
  String get storyRelatedEmpty => 'No related posts yet';

  @override
  String get storyViewAll => 'View all';

  @override
  String get storyEditAction => 'Edit post';

  @override
  String get storyDeleteTitle => 'Delete post?';

  @override
  String get storyDeleteMessage => 'The post will be removed from public feed.';

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
  String get storyPlaceHint => 'City or country';

  @override
  String get storyCountryHint => 'Country';

  @override
  String get storyCityHint => 'City';

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
  String get storyEditorTitle => 'Post editor';

  @override
  String get storyEditorQuickPostTitle => 'Quick post';

  @override
  String get storyEditorQuickPostSubtitle =>
      'Share a short update, question, or local tip with the community.';

  @override
  String get storyEditorQuickPostHint => 'What do you want to share?';

  @override
  String get storyEditorLoading => 'Loading story';

  @override
  String get storyEditorLoadFailed => 'Unable to load story for editing.';

  @override
  String get storyEditorEditMode => 'Edit';

  @override
  String get storyEditorPreviewMode => 'Preview';

  @override
  String get storyEditorRecoveryTitle => 'Recover unsaved draft?';

  @override
  String get storyEditorRecoveryMessage =>
      'A local recovery copy is available for this story.';

  @override
  String get storyEditorRecoveryDiscard => 'Discard';

  @override
  String get storyEditorRecoveryRestore => 'Restore';

  @override
  String get storyEditorDiscardChangesTitle => 'Discard post changes?';

  @override
  String get storyEditorDiscardChangesMessage => 'Unsaved edits may be lost.';

  @override
  String get storyEditorKeepEditing => 'Keep editing';

  @override
  String get storyEditorMetadataTitle => 'Publication setup';

  @override
  String get storyEditorTitleFieldHint => 'A precise, searchable title';

  @override
  String get storyEditorTemplateAction => 'Templates';

  @override
  String get storyEditorTemplateSemantic => 'Choose story template';

  @override
  String get storyEditorTemplatePlaceholder => 'Choose a template';

  @override
  String get storyEditorTemplateWeekendGuide => 'Weekend guide';

  @override
  String get storyEditorTemplatePhotoEssay => 'Photo essay';

  @override
  String get storyEditorTemplateFoodNotes => 'Food notes';

  @override
  String get storyEditorTemplateCityWalk => 'City walk';

  @override
  String get storyEditorTemplateHiddenGems => 'Hidden gems';

  @override
  String get storyEditorTemplatePracticalTips => 'Practical tips';

  @override
  String get storyEditorTemplateCultureRoute => 'Culture route';

  @override
  String get storyEditorTemplateWeekendHeading => 'Weekend plan';

  @override
  String get storyEditorTemplateWeekendList =>
      'Morning stop\nLocal food\nEvening view';

  @override
  String get storyEditorTemplatePhotoHeading => 'Photo story';

  @override
  String get storyEditorTemplateFoodHeading => 'Where to eat';

  @override
  String get storyEditorTemplateFoodParagraph =>
      'Describe the dish, price range, and best time to visit.';

  @override
  String get storyEditorTemplateCityWalkHeading => 'Walking route';

  @override
  String get storyEditorTemplateCityWalkList =>
      'Starting point\nMain street\nPause spot\nFinal view';

  @override
  String get storyEditorTemplateCityWalkParagraph =>
      'Add distance, approximate timing, and the easiest way to reach the start.';

  @override
  String get storyEditorTemplateHiddenGemsHeading =>
      'Places not everyone knows';

  @override
  String get storyEditorTemplateHiddenGemsList =>
      'Why it is worth a stop\nWhen it is quiet\nWhat to see nearby';

  @override
  String get storyEditorTemplateHiddenGemsCallout =>
      'Add practical details: entry, schedule, safety, cash, or reservation notes.';

  @override
  String get storyEditorTemplatePracticalTipsHeading =>
      'Good to know before the trip';

  @override
  String get storyEditorTemplatePracticalTipsList =>
      'When to go\nHow to get there\nBudget to plan\nWhat to bring';

  @override
  String get storyEditorTemplatePracticalTipsCallout =>
      'Add an honest tip that saves time or helps avoid a common mistake.';

  @override
  String get storyEditorTemplateCultureRouteHeading => 'Culture route';

  @override
  String get storyEditorTemplateCultureRouteParagraph =>
      'Explain which traditions, buildings, museums, or local stories help readers understand this place.';

  @override
  String get storyEditorTemplateCultureRouteQuote =>
      'Add a phrase, observation, or short fact that sets the mood for the route.';

  @override
  String get storyEditorTemplateConflictTitle => 'Apply new story structure?';

  @override
  String storyEditorTemplateConflictMessage(Object format, Object category) {
    return 'This structure suggests $format / $category. Choose how to apply it without losing your draft.';
  }

  @override
  String get storyEditorTemplateConflictReplace => 'Replace template';

  @override
  String get storyEditorTemplateConflictReplaceDescription =>
      'Remove untouched template blocks, keep your edited text, and add the new structure.';

  @override
  String get storyEditorTemplateConflictAppend => 'Add to current story';

  @override
  String get storyEditorTemplateConflictAppendDescription =>
      'Keep everything and append the new structure below your current blocks.';

  @override
  String get storyEditorTemplateConflictMetadataOnly => 'Update type and topic';

  @override
  String get storyEditorTemplateConflictMetadataOnlyDescription =>
      'Change only the content type and topic without changing blocks.';

  @override
  String get storyEditorFormatLabel => 'Content type';

  @override
  String get storyEditorPlaceLabel => 'Place';

  @override
  String get storyEditorCountryCodeLabel => 'Country code';

  @override
  String get storyEditorCountryCodeHint => 'KZ';

  @override
  String get storyEditorCityPlaceIdLabel => 'City/place id';

  @override
  String get storyEditorTagsHint => 'mountains, food, weekend';

  @override
  String get storyEditorCoverSelected => 'Cover selected';

  @override
  String get storyEditorCoverRequired => 'Cover required';

  @override
  String get storyEditorReplaceCover => 'Replace cover';

  @override
  String get storyEditorAddCover => 'Add cover';

  @override
  String get storyEditorClear => 'Clear';

  @override
  String get storyEditorToolbarAddBlock => 'Add block';

  @override
  String get storyEditorToolbarHeading => 'Heading';

  @override
  String get storyEditorToolbarBold => 'Bold';

  @override
  String get storyEditorToolbarItalic => 'Italic';

  @override
  String get storyEditorToolbarStrikethrough => 'Strikethrough';

  @override
  String get storyEditorToolbarUnderline => 'Underline';

  @override
  String get storyEditorToolbarList => 'List';

  @override
  String get storyEditorToolbarQuote => 'Quote';

  @override
  String get storyEditorToolbarImage => 'Image';

  @override
  String get storyEditorToolbarUndo => 'Undo';

  @override
  String get storyEditorToolbarRedo => 'Redo';

  @override
  String get storyEditorAddBlockTitle => 'Add block';

  @override
  String get storyEditorBlockParagraph => 'Paragraph';

  @override
  String get storyEditorBlockParagraphDescription => 'Body text for the story';

  @override
  String get storyEditorBlockHeading => 'Heading';

  @override
  String get storyEditorBlockHeadingDescription => 'Section title';

  @override
  String get storyEditorBlockList => 'List';

  @override
  String get storyEditorBlockListDescription => 'Useful tips or steps';

  @override
  String get storyEditorBlockImage => 'Image';

  @override
  String get storyEditorBlockImageDescription => 'Single media upload';

  @override
  String get storyEditorBlockGallery => 'Gallery';

  @override
  String get storyEditorBlockGalleryDescription => 'Multiple images';

  @override
  String get storyEditorBlockQuote => 'Quote';

  @override
  String get storyEditorBlockQuoteDescription => 'A highlighted sentence';

  @override
  String get storyEditorBlockCallout => 'Callout';

  @override
  String get storyEditorBlockCalloutDescription => 'Important travel note';

  @override
  String get storyEditorBlockDivider => 'Divider';

  @override
  String get storyEditorBlockDividerDescription => 'Visual section break';

  @override
  String get storyEditorBlockPlaceReference => 'Place reference';

  @override
  String get storyEditorBlockPlaceReferenceDescription =>
      'Link a place to the story';

  @override
  String get storyEditorBlockNumberedList => 'Numbered list';

  @override
  String get storyEditorStartWithBlockTitle => 'Start with a block';

  @override
  String get storyEditorStartWithBlockSubtitle =>
      'Add text, media, places, callouts, or dividers to shape the story.';

  @override
  String get storyEditorPlaceNameHint => 'Place name';

  @override
  String get storyEditorTextHintHeading => 'Write a clear section heading';

  @override
  String get storyEditorTextHintBulletedList => 'Add list items, one per line';

  @override
  String get storyEditorTextHintNumberedList =>
      'Add ordered steps, one per line';

  @override
  String get storyEditorTextHintQuote => 'Add a quote or memorable line';

  @override
  String get storyEditorTextHintCallout => 'Highlight a practical tip';

  @override
  String get storyEditorTextHintParagraph => 'Write your story';

  @override
  String storyEditorDeleteBlockSemantic(Object block) {
    return 'Delete $block block';
  }

  @override
  String storyEditorReorderBlockSemantic(Object block) {
    return 'Drag to reorder $block block';
  }

  @override
  String get storyEditorPublishReadiness => 'Publish readiness';

  @override
  String get storyEditorChecklistTitle => 'Title';

  @override
  String get storyEditorChecklistFormat => 'Content type';

  @override
  String get storyEditorChecklistCategory => 'Topic';

  @override
  String get storyEditorChecklistCover => 'Cover';

  @override
  String get storyEditorChecklistPlace => 'Place';

  @override
  String get storyEditorChecklistCountry => 'Country';

  @override
  String get storyEditorChecklistContent => 'Content';

  @override
  String get storyEditorChecklistMedia => 'Media';

  @override
  String get storyEditorChecklistReady => 'Ready';

  @override
  String get storyEditorChecklistNeedsAttention => 'Needs attention';

  @override
  String get storyEditorChecklistOpen => 'Open';

  @override
  String get storyEditorConflictFallback => 'Story was changed elsewhere.';

  @override
  String get storyEditorSaveDraft => 'Save draft';

  @override
  String get storyEditorPublish => 'Publish';

  @override
  String get storyEditorPublishSemantic => 'Publish story';

  @override
  String get storyEditorAutosaveIdle => 'Idle';

  @override
  String get storyEditorAutosaveSaving => 'Saving';

  @override
  String get storyEditorAutosaveSaved => 'Saved';

  @override
  String get storyEditorAutosaveFailed => 'Needs attention';

  @override
  String get storyEditorAutosaveConflict => 'Conflict';

  @override
  String get storyEditorPublishNotReady => 'Story is not ready to publish.';

  @override
  String get storyEditorMediaRetrySemantic => 'Retry media upload';

  @override
  String get storyEditorMediaRemoveSemantic => 'Remove media upload';

  @override
  String get storyEditorMediaRetry => 'Retry';

  @override
  String get storyEditorMediaRemove => 'Remove';

  @override
  String get storyEditorMediaQueued => 'Queued for upload';

  @override
  String get storyEditorMediaUploading => 'Uploading';

  @override
  String get storyEditorMediaFailed => 'Upload failed';

  @override
  String get storyEditorMediaComplete => 'Upload complete';

  @override
  String get storyEditorMediaRemoved => 'Removed';

  @override
  String get storyEditorMediaLocalPreviewUnavailable =>
      'Local preview unavailable. Remove and add this media again.';

  @override
  String get storyEditorMediaErrorRetryUpload => 'Retry the media upload.';

  @override
  String get storyEditorMediaErrorInterrupted =>
      'Upload was interrupted. Retry to continue.';

  @override
  String get storyEditorMediaErrorMissingSource =>
      'Local media source is unavailable. Remove and add this media again.';

  @override
  String get storyEditorMediaErrorUploadFailed =>
      'Media upload failed. Please try again.';

  @override
  String get storyEditorImagePickTooLarge =>
      'Image is too large. Choose an image up to 20 MB.';

  @override
  String get storyEditorImagePickUnsupported =>
      'Choose a JPG, PNG, or WebP image.';

  @override
  String get storyEditorImagePickFailed =>
      'Could not open this image. Please try another one.';

  @override
  String get storyEditorValidationTitleRequired => 'Story title is required.';

  @override
  String get storyEditorValidationFormatRequired => 'Story format is required.';

  @override
  String get storyEditorValidationCategoryRequired =>
      'Story category is required.';

  @override
  String get storyEditorValidationCoverRequired => 'Story cover is required.';

  @override
  String get storyEditorValidationPlaceRequired => 'Story place is required.';

  @override
  String get storyEditorValidationCountryRequired =>
      'Story country is required.';

  @override
  String get storyEditorValidationDraftRequired =>
      'Add a title or at least one story block to save a draft.';

  @override
  String get storyEditorValidationContentRequired =>
      'Write at least one story block before publishing.';

  @override
  String get storyEditorValidationMediaPending =>
      'Wait until media uploads finish.';

  @override
  String get postCreateRateLimitTitle => 'Post limit';

  @override
  String postCreateRateLimitMessage(int minutes) {
    return 'You have created the maximum number of posts in the last hour. You can create another post in about $minutes min.';
  }

  @override
  String get postCreateRateLimitAction => 'Got it';

  @override
  String get postCreatePreflightFailed =>
      'Could not check the post limit. We will check again when you publish.';

  @override
  String get chatListTitle => 'Chats';

  @override
  String get chatListLoadFailed => 'Failed to load chats';

  @override
  String get chatListEmpty => 'No conversations yet';

  @override
  String get chatListPersonalTab => 'Personal';

  @override
  String get chatListActivitiesTab => 'Activities';

  @override
  String get chatListExcursionsTab => 'Tours';

  @override
  String get chatListSearchHint => 'Chats';

  @override
  String get chatListSearchEmpty => 'No chats found';

  @override
  String get chatMuteNotificationsAction => 'Mute notifications';

  @override
  String get chatUnmuteNotificationsAction => 'Unmute notifications';

  @override
  String get chatMuteUpdateFailed => 'Failed to update chat notifications';

  @override
  String get chatBlockUserAction => 'Block';

  @override
  String get chatUnblockUserAction => 'Unblock';

  @override
  String get chatUserBlockUpdateFailed => 'Failed to update user block status';

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
  String get chatMessageRemovedByModerator => 'Message removed by moderator';

  @override
  String chatModeratorComment(Object comment) {
    return 'Moderator comment: $comment';
  }

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
  String get chatLastMessagePhoto => 'Photo';

  @override
  String get chatLastMessageVideo => 'Video';

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
  String get stickersSearchHint => 'Stickers';

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
  String get chatCameraFlashOffButtonLabel => 'Flash off';

  @override
  String get chatCameraFlashAutoButtonLabel => 'Auto flash';

  @override
  String get chatCameraFlashOnButtonLabel => 'Flash on';

  @override
  String get chatCameraCloseButtonLabel => 'Close camera';

  @override
  String get chatCameraCapturePhotoButtonLabel => 'Take photo';

  @override
  String get chatCameraRecordVideoButtonLabel => 'Record video';

  @override
  String get chatCameraStopRecordingButtonLabel => 'Stop recording';

  @override
  String get chatCameraReviewCancelButtonLabel => 'Cancel';

  @override
  String get chatCameraReviewSendButtonLabel => 'Send';

  @override
  String get chatCameraReviewPlayButtonLabel => 'Play video';

  @override
  String get chatCameraReviewPauseButtonLabel => 'Pause video';

  @override
  String get chatCameraReviewTrimLabel => 'Trim';

  @override
  String get chatCameraReviewProcessing => 'Processing...';

  @override
  String get chatCameraTrimFailed =>
      'Could not trim this video. Try a different trim range or send the original.';

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
  String get chatActivityChatClosed => 'This chat is now read-only.';

  @override
  String get chatActivityChatClosedHistoryNotice =>
      'The event has ended. Messages can no longer be sent in this chat.';

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
  String get chatCopyAction => 'Copy';

  @override
  String get chatForwardAction => 'Forward';

  @override
  String get chatMessageCopied => 'Message copied';

  @override
  String get chatForwardSheetTitle => 'Forward to';

  @override
  String get chatForwardFailed =>
      'Could not forward the message. Please try again.';

  @override
  String get chatForwardSuccess => 'Message forwarded';

  @override
  String get chatNoForwardTargets => 'No available chats';

  @override
  String get chatForwardedLabel => 'Forwarded';

  @override
  String get chatStoryReplyLabel => 'Reply to story';

  @override
  String get chatStoryReplyUnavailable => 'Story is no longer available';

  @override
  String chatForwardedFrom(Object name) {
    return 'Forwarded from $name';
  }

  @override
  String chatForwardCount(Object count) {
    return 'Forwarded $count';
  }

  @override
  String get chatReactionsByTitle => 'Reactions';

  @override
  String chatReactionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactions',
      one: '1 reaction',
    );
    return '$_temp0';
  }

  @override
  String get chatReadByTitle => 'Read by';

  @override
  String chatReadByCount(Object count) {
    return 'Read by $count';
  }

  @override
  String get chatReadAtSeparator => 'at';

  @override
  String get chatNoStatusDetails => 'No status details yet';

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
  String get chatSharedVoiceTab => 'Audio messages';

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
  String get chatSharedNoVoiceTitle => 'No voice messages yet';

  @override
  String get chatSharedNoVoiceSubtitle =>
      'Voice messages from this chat will appear here.';

  @override
  String chatSharedFileFallback(Object id) {
    return 'File $id';
  }

  @override
  String get chatSharedUnknownFile => 'Unknown file';

  @override
  String get chatSharedGoToMessageAction => 'Go to message';

  @override
  String get chatExternalLinkTitle => 'Open external link?';

  @override
  String chatExternalLinkMessage(Object url) {
    return 'This link opens a third-party resource:\n$url';
  }

  @override
  String get chatExternalLinkOpenAction => 'Open';

  @override
  String get chatExternalLinkOpenFailed => 'Could not open this link.';

  @override
  String get chatSharedLoadFailed => 'Could not load content';

  @override
  String get chatSharedLoadFailedSubtitle =>
      'Please check the connection and retry.';

  @override
  String get chatSharedPartialLoadWarning =>
      'Some older shared items could not be loaded.';

  @override
  String get guideCalendarTitle => 'Guide calendar';

  @override
  String get guideCalendarAddSlot => 'Slot';

  @override
  String get guideCalendarEditSlot => 'Edit slot';

  @override
  String get guideCalendarEmptyDay => 'No slots for this day';

  @override
  String get guideCalendarAvailable => 'Available';

  @override
  String get guideCalendarBooked => 'Booked';

  @override
  String get guideCalendarClosed => 'Closed';

  @override
  String get guideCalendarCancelled => 'Cancelled';

  @override
  String get guideCalendarCompleted => 'Completed';

  @override
  String get guideCalendarViewSlot => 'Slot details';

  @override
  String get guideCalendarReadonlyCompletedSlot =>
      'This slot has already finished. It is kept in the calendar for history and can only be viewed.';

  @override
  String guideCalendarCancelReason(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String get guideCalendarAutoCancelNoBookings =>
      'no one booked this slot at least 2 hours before start';

  @override
  String get guideCalendarRepeatWeekly => 'Repeat weekly';

  @override
  String get guideCalendarConflictTitle =>
      'This time overlaps another excursion';

  @override
  String get guideCalendarSuggestNextTime => 'Choose the next available time';

  @override
  String get guideCalendarDeleteSlot => 'Delete';

  @override
  String get guideCalendarCancelSlot => 'Cancel';

  @override
  String get guideCalendarCloseSlot => 'Close';

  @override
  String get guideCalendarOfferLabel => 'Published offer';

  @override
  String get guideCalendarNoPublishedOffers =>
      'Publish an excursion offer first to add it to the schedule.';

  @override
  String get guideCalendarOfferRequired => 'Choose an excursion offer';

  @override
  String get guideCalendarCurrentOfferFallback => 'Current offer';

  @override
  String guideCalendarOfferDuration(Object minutes) {
    return '$minutes min';
  }

  @override
  String guideCalendarOfferCapacity(Object count) {
    return '$count seats';
  }

  @override
  String get guideCalendarDateLabel => 'Date';

  @override
  String get guideCalendarDateHint => 'dd.mm.yyyy';

  @override
  String get guideCalendarInvalidDate => 'Enter the date as dd.mm.yyyy';

  @override
  String get guideCalendarTimeLabel => 'Time';

  @override
  String get guideCalendarTimeHint => 'hh:mm';

  @override
  String get guideCalendarInvalidTime => 'Enter the time as hh:mm';

  @override
  String get guideCalendarCapacityLabel => 'Seats';

  @override
  String guideCalendarCapacityMax(Object count) {
    return 'Maximum for this offer: $count';
  }

  @override
  String guideCalendarCapacityTooHigh(Object count) {
    return 'This offer allows up to $count seats';
  }

  @override
  String get guideCalendarSlotLeadTimeTooSoon =>
      'Choose a date and time at least 3 hours before the start.';

  @override
  String get guideCalendarSaveSlot => 'Save';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Important updates for trips, activities, and excursions';

  @override
  String get notificationsCategoriesEmptyTitle => 'All quiet for now';

  @override
  String get notificationsCategoriesEmptySubtitle =>
      'The latest updates for your categories will appear here.';

  @override
  String get notificationsLoadFailedTitle => 'Could not load notifications';

  @override
  String get notificationsLoadFailedSubtitle =>
      'Check your connection and try again.';

  @override
  String get notificationsCategoryEmptyTitle =>
      'No notifications in this category yet';

  @override
  String get notificationsCategoryEmptySubtitle =>
      'New events will appear here automatically.';

  @override
  String get notificationsReadAll => 'Mark all as read';

  @override
  String get notificationsReadAllDone =>
      'All notifications in this category are read';

  @override
  String notificationsUnreadCount(Object count) {
    return '$count new';
  }

  @override
  String get notificationsCategoryActivity => 'Activities';

  @override
  String get notificationsCategoryExcursion => 'Excursions';

  @override
  String get notificationsCategoryBooking => 'Bookings';

  @override
  String get notificationsCategoryChat => 'Messages';

  @override
  String get notificationsCategoryContent => 'Posts and stories';

  @override
  String get notificationsCategorySystem => 'System';

  @override
  String get notificationsCategoryGeneral => 'General';

  @override
  String notificationsCategoryFallback(Object category) {
    return 'Category $category';
  }

  @override
  String get notificationsSomeone => 'Someone';

  @override
  String get notificationsPriorityHigh => 'Important';

  @override
  String notificationsStoryLikeTitle(Object actor) {
    return '$actor liked your story';
  }

  @override
  String get notificationsStoryLikeBody =>
      'Open the story to see the reaction.';

  @override
  String notificationsStoryReplyTitle(Object actor) {
    return '$actor replied to your story';
  }

  @override
  String get notificationsStoryReplyBody => 'The reply was sent to your chat.';

  @override
  String notificationsPostLikeTitle(Object actor) {
    return '$actor liked your post';
  }

  @override
  String get notificationsPostLikeBody => 'Open the post to see the reaction.';

  @override
  String notificationsPostCommentTitle(Object actor) {
    return '$actor commented on your post';
  }

  @override
  String get notificationsPostCommentBody =>
      'Open the post to continue the discussion.';

  @override
  String notificationsChatMessageTitle(Object actor) {
    return 'New message from $actor';
  }

  @override
  String get notificationsChatMessageBody => 'Open chats to reply.';

  @override
  String notificationsActivityJoinedTitle(Object actor) {
    return '$actor joined your activity';
  }

  @override
  String get notificationsActivityJoinedBody =>
      'Open the activity to see participants.';

  @override
  String get notificationsActivityParticipantWaitlistedTitle =>
      'Participant joined the waitlist';

  @override
  String get notificationsActivityParticipantWaitlistedBody =>
      'Open the activity to manage the waitlist.';

  @override
  String get notificationsActivityParticipantLeftTitle =>
      'Participant left the activity';

  @override
  String get notificationsActivityParticipantLeftBody =>
      'Open the activity to check the current participant list.';

  @override
  String get notificationsActivityLateCancellationTitle => 'Late cancellation';

  @override
  String get notificationsActivityLateCancellationBody =>
      'A participant cancelled close to the start time.';

  @override
  String get notificationsActivityCancelledTitle => 'Activity cancelled';

  @override
  String notificationsActivityCancelledBody(Object activity) {
    return 'Activity \"$activity\" was cancelled.';
  }

  @override
  String get notificationsActivityCancelledBodyGeneric =>
      'This activity was cancelled.';

  @override
  String get notificationsActivityConfirmedTitle => 'Activity confirmed';

  @override
  String get notificationsActivityConfirmedBody =>
      'Open the activity to see the latest details.';

  @override
  String get notificationsActivityCompletedTitle => 'Activity completed';

  @override
  String get notificationsActivityCompletedBody =>
      'You can now review your experience.';

  @override
  String get notificationsExcursionBookingCreatedTitle =>
      'New excursion booking';

  @override
  String get notificationsExcursionBookingCreatedBody =>
      'Open the guide dashboard to see booking details.';

  @override
  String get notificationsExcursionBookingCancelledTitle =>
      'Excursion booking cancelled';

  @override
  String get notificationsExcursionBookingCancelledBody =>
      'A traveler cancelled this excursion.';

  @override
  String get notificationsExcursionGuestsUpdatedTitle => 'Guest count updated';

  @override
  String get notificationsExcursionGuestsUpdatedBody =>
      'Open the guide dashboard to check the updated booking.';

  @override
  String get notificationsExcursionAttendanceTitle => 'Traveler checked in';

  @override
  String get notificationsExcursionAttendanceBody =>
      'A traveler checked in for this excursion.';

  @override
  String get notificationsExcursionCancelledTitle => 'Excursion cancelled';

  @override
  String get notificationsExcursionCancelledBody =>
      'The guide cancelled this excursion.';

  @override
  String get notificationsExcursionStartsSoonTitle => 'Excursion starts soon';

  @override
  String get notificationsExcursionStartsSoonBody =>
      'The booking window is closed. Open the excursion to check guests.';

  @override
  String get notificationsExcursionCompletedTitle => 'How was your excursion?';

  @override
  String get notificationsExcursionCompletedBody =>
      'The excursion is complete. You can leave a review.';

  @override
  String get notificationsExcursionPublishedTitle => 'Excursion published';

  @override
  String get notificationsExcursionPublishedBody =>
      'Your excursion is now visible to travelers.';

  @override
  String get notificationsExcursionRejectedTitle => 'Excursion needs changes';

  @override
  String get notificationsExcursionRejectedBody =>
      'Open the guide dashboard to check the review notes.';

  @override
  String get notificationsJustNow => 'just now';

  @override
  String notificationsMinutesAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String notificationsHoursAgo(Object hours) {
    return '$hours h ago';
  }

  @override
  String notificationsDaysAgo(Object days) {
    return '$days d ago';
  }
}
