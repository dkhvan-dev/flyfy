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
  /// **'We use these details only to verify your identity and guide status.'**
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
  /// **'Take the photo in even light so every detail remains readable.'**
  String get guideVerificationNoGlareHint;

  /// No description provided for @guideVerificationFullFrame.
  ///
  /// In en, this message translates to:
  /// **'Full frame'**
  String get guideVerificationFullFrame;

  /// No description provided for @guideVerificationFullFrameHint.
  ///
  /// In en, this message translates to:
  /// **'All edges of the document should be visible in the image.'**
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

  /// No description provided for @guideVerificationDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'I confirm that this document is valid, not expired, and the photo provided is clearly legible for automated verification systems.'**
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

  /// No description provided for @guideVerificationOfficialTourGuideLicense.
  ///
  /// In en, this message translates to:
  /// **'Official tour guide license'**
  String get guideVerificationOfficialTourGuideLicense;

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
  /// **'A certificate, license, or other professional document works here.'**
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
  /// **'You have current first aid training or a valid certificate.'**
  String get guideVerificationFirstAidHint;

  /// No description provided for @guideVerificationLanguageProficiency.
  ///
  /// In en, this message translates to:
  /// **'Foreign languages'**
  String get guideVerificationLanguageProficiency;

  /// No description provided for @guideVerificationLanguageProficiencyHint.
  ///
  /// In en, this message translates to:
  /// **'You can host activities and tours in more than one language.'**
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
  /// **'I understand that FlyFy may reject the application if any information is inaccurate or the uploaded documents are not suitable.'**
  String get guideVerificationTermsBody;

  /// No description provided for @guideVerificationAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to document review and data processing for guide status verification.'**
  String get guideVerificationAgreement;

  /// No description provided for @guideVerificationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get guideVerificationSubmit;

  /// No description provided for @guideVerificationReviewNote.
  ///
  /// In en, this message translates to:
  /// **'After submission, you can track the application status in your profile.'**
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
  /// **'Confirm access with Face ID, your fingerprint, or another available biometric. After 3 failed attempts, PIN unlock will be shown.'**
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
  /// **'Use biometrics'**
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

  /// No description provided for @profileDisplayNameTaken.
  ///
  /// In en, this message translates to:
  /// **'This display name is already taken'**
  String get profileDisplayNameTaken;

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
  /// **'FlyFy Guide'**
  String get profileGuideTitle;

  /// No description provided for @profileEmptyBioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'There is no public description yet. Once the profile is filled in, a short bio will appear here.'**
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

  /// No description provided for @profileBlogsStat.
  ///
  /// In en, this message translates to:
  /// **'Blogs'**
  String get profileBlogsStat;

  /// No description provided for @profileFollowersStat.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowersStat;

  /// No description provided for @profileJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'My journey'**
  String get profileJourneyTitle;

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
  /// **'Push, email, and SMS updates for your activity flow.'**
  String get profileNotificationsRowSubtitle;

  /// No description provided for @profileSecurityRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & data'**
  String get profileSecurityRowTitle;

  /// No description provided for @profileSecurityRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PIN, biometrics, and the protected local session.'**
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

  /// No description provided for @profileBlogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Blogs'**
  String get profileBlogsTitle;

  /// No description provided for @profileBlogsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Public notes and travel stories are not available in the app yet.'**
  String get profileBlogsUnavailable;

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

  /// No description provided for @profileFollowUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update follow status'**
  String get profileFollowUpdateFailed;

  /// No description provided for @profileMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get profileMessageAction;

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

  /// No description provided for @profileSettingsSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSettingsSecuritySection;

  /// No description provided for @profileSettingsSecurityPinTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN & biometrics'**
  String get profileSettingsSecurityPinTitle;

  /// No description provided for @profileSettingsSecurityPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the security screen to manage your local sign-in protection.'**
  String get profileSettingsSecurityPinSubtitle;

  /// No description provided for @profileAccountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountSectionTitle;

  /// No description provided for @profileSettingsEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name, photo, bio, and core profile details.'**
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
  /// **'Choose how FlyFy keeps you updated about activity changes, participation, and new opportunities.'**
  String get profileNotificationsHeroSubtitle;

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
  /// **'Instant updates for activities, status changes, and new messages.'**
  String get profileNotificationsPushSubtitle;

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

  /// No description provided for @profileNotificationsMarketingTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections & offers'**
  String get profileNotificationsMarketingTitle;

  /// No description provided for @profileNotificationsMarketingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Travel inspiration, place collections, and special FlyFy offers.'**
  String get profileNotificationsMarketingSubtitle;

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
  /// **'This section combines local unlock methods and upcoming account protection tools.'**
  String get profileSecurityHeroSubtitle;

  /// No description provided for @profileSecurityLocalAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Local access'**
  String get profileSecurityLocalAccessSection;

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

  /// No description provided for @profileSecurityPinTitle.
  ///
  /// In en, this message translates to:
  /// **'App PIN'**
  String get profileSecurityPinTitle;

  /// No description provided for @profileSecurityPinEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A PIN is configured and is used for quick app unlock.'**
  String get profileSecurityPinEnabledSubtitle;

  /// No description provided for @profileSecurityPinMissingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No PIN is configured yet. The app will ask to create one after the next authentication.'**
  String get profileSecurityPinMissingSubtitle;

  /// No description provided for @profileSecurityBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get profileSecurityBiometricTitle;

  /// No description provided for @profileSecurityBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow app unlock with Face ID, fingerprint, or other supported biometrics.'**
  String get profileSecurityBiometricSubtitle;

  /// No description provided for @profileSecurityBiometricNeedsPin.
  ///
  /// In en, this message translates to:
  /// **'An app PIN must be configured first.'**
  String get profileSecurityBiometricNeedsPin;

  /// No description provided for @profileSecurityBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available or not configured on this device.'**
  String get profileSecurityBiometricUnavailable;

  /// No description provided for @profileSecurityProtectedSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected session'**
  String get profileSecurityProtectedSessionTitle;

  /// No description provided for @profileSecurityProtectedSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A local session is stored. After restart, the app can be unlocked quickly.'**
  String get profileSecurityProtectedSessionSubtitle;

  /// No description provided for @profileSecurityNoStoredSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No active stored session was found. Protection will turn on automatically after the next sign in.'**
  String get profileSecurityNoStoredSessionSubtitle;

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

  /// No description provided for @participantStatusAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get participantStatusAttended;

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

  /// No description provided for @mapPlacesCount.
  ///
  /// In en, this message translates to:
  /// **'Places found: {count}'**
  String mapPlacesCount(int count);

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
  /// **'Please enter a maximum between 1 and 100 participants'**
  String get createMaxParticipantsValidation;

  /// No description provided for @createMinParticipantsValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a minimum of at least 1 participant'**
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
  /// **'Price cannot be changed if other participants have already joined'**
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
  /// **'Discover Stories'**
  String get storiesDiscoverTitle;

  /// No description provided for @storiesNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get storiesNavLabel;

  /// No description provided for @storiesActivitiesNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get storiesActivitiesNavLabel;

  /// No description provided for @storySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search stories, authors, or places'**
  String get storySearchHint;

  /// No description provided for @storyFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get storyFilterCategory;

  /// No description provided for @storyFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get storyFilterCountry;

  /// No description provided for @storyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storyFilterAll;

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
  /// **'Share Your Story'**
  String get storyCreateCta;

  /// No description provided for @storyCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create the first story'**
  String get storyCreateFirst;

  /// No description provided for @storyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get storyEmptyTitle;

  /// No description provided for @storyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to publish a travel note, local guide, or visual essay.'**
  String get storyEmptySubtitle;

  /// No description provided for @storyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load stories'**
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

  /// No description provided for @storyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Story Details'**
  String get storyDetailsTitle;

  /// No description provided for @storyLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Story link copied'**
  String get storyLinkCopied;

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
  /// **'Related Stories'**
  String get storyRelatedTitle;

  /// No description provided for @storyRelatedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No related stories yet'**
  String get storyRelatedEmpty;

  /// No description provided for @storyViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get storyViewAll;

  /// No description provided for @storyEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Story'**
  String get storyEditAction;

  /// No description provided for @storyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete story?'**
  String get storyDeleteTitle;

  /// No description provided for @storyDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The story will be removed from public feed.'**
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
  /// **'Search city or country'**
  String get storyPlaceHint;

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
