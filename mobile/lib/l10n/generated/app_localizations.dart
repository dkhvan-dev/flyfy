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
  /// **'Search time zone, city, or UTC'**
  String get profileTimezoneSearchHint;

  /// No description provided for @profileTimezoneNoResults.
  ///
  /// In en, this message translates to:
  /// **'No time zones found'**
  String get profileTimezoneNoResults;

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

  /// No description provided for @profileCurrencySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search currency, code, or symbol'**
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
  /// **'You can host activities and excursions in more than one language.'**
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

  /// No description provided for @profileIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile is incomplete'**
  String get profileIncompleteTitle;

  /// No description provided for @profileIncompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill in your first name, last name, and country to unlock all FlyFy features'**
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

  /// No description provided for @profileCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get profileCountryRequired;

  /// No description provided for @profileRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileRequiredTitle;

  /// No description provided for @profileRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'To continue, enter your first name, last name, and country in your profile. This helps reduce fake accounts and increases trust between users.'**
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

  /// No description provided for @profileFollowersTitle.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowersTitle;

  /// No description provided for @profileFollowersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search followers'**
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
  /// **'Search people'**
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
  /// **'Account protection, data export, and privacy controls.'**
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
  /// **'Popular stories'**
  String get profilePopularStoriesTitle;

  /// No description provided for @profileViewAllStories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get profileViewAllStories;

  /// No description provided for @profileStoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load stories'**
  String get profileStoriesLoadFailed;

  /// No description provided for @profileStoriesLoadFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get profileStoriesLoadFailedHint;

  /// No description provided for @profileStoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get profileStoriesEmptyTitle;

  /// No description provided for @profileStoriesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Published stories from this user will appear here.'**
  String get profileStoriesEmptySubtitle;

  /// No description provided for @profileUserStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'User stories'**
  String get profileUserStoriesTitle;

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
  /// **'Search friends'**
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

  /// No description provided for @homeExploringLocation.
  ///
  /// In en, this message translates to:
  /// **'{location}'**
  String homeExploringLocation(Object location);

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search activities, attractions, excursions...'**
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
  /// **'Top Stories'**
  String get homeTopStories;

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

  /// No description provided for @homeServiceAttractions.
  ///
  /// In en, this message translates to:
  /// **'Attractions'**
  String get homeServiceAttractions;

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

  /// No description provided for @attractionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover attractions'**
  String get attractionsTitle;

  /// No description provided for @attractionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Where to next?'**
  String get attractionsSearchHint;

  /// No description provided for @attractionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load attractions'**
  String get attractionsLoadFailed;

  /// No description provided for @attractionsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get attractionsSeeAll;

  /// No description provided for @attractionsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No attractions found'**
  String get attractionsNoResults;

  /// No description provided for @attractionsFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get attractionsFiltersTitle;

  /// No description provided for @attractionsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get attractionsSortLabel;

  /// No description provided for @attractionsSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get attractionsSortRating;

  /// No description provided for @attractionsSortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get attractionsSortDuration;

  /// No description provided for @attractionsSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get attractionsSortPrice;

  /// No description provided for @attractionFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get attractionFilterClearAll;

  /// No description provided for @attractionFilterCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get attractionFilterCategoriesSection;

  /// No description provided for @attractionFilterCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All Spots'**
  String get attractionFilterCategoryAll;

  /// No description provided for @attractionFilterCategoryParks.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get attractionFilterCategoryParks;

  /// No description provided for @attractionFilterCategoryMuseums.
  ///
  /// In en, this message translates to:
  /// **'Museums'**
  String get attractionFilterCategoryMuseums;

  /// No description provided for @attractionFilterCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get attractionFilterCategoryNature;

  /// No description provided for @attractionFilterCategoryArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get attractionFilterCategoryArchitecture;

  /// No description provided for @attractionFilterCategoryBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get attractionFilterCategoryBeach;

  /// No description provided for @attractionFilterCategoryTemple.
  ///
  /// In en, this message translates to:
  /// **'Temple'**
  String get attractionFilterCategoryTemple;

  /// No description provided for @attractionFilterCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get attractionFilterCategoryEntertainment;

  /// No description provided for @attractionFilterCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get attractionFilterCategoryFood;

  /// No description provided for @attractionFilterCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get attractionFilterCategoryShopping;

  /// No description provided for @attractionFilterCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get attractionFilterCategoryOther;

  /// No description provided for @attractionFilterCategoryHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get attractionFilterCategoryHistory;

  /// No description provided for @attractionFilterCategoryAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get attractionFilterCategoryAdventure;

  /// No description provided for @attractionFilterCountrySection.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get attractionFilterCountrySection;

  /// No description provided for @attractionFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get attractionFilterCountryAll;

  /// No description provided for @attractionFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search country, code, or phone'**
  String get attractionFilterCountrySearchHint;

  /// No description provided for @attractionFilterCountryNoResults.
  ///
  /// In en, this message translates to:
  /// **'Country not found'**
  String get attractionFilterCountryNoResults;

  /// No description provided for @attractionFilterMinRatingSection.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get attractionFilterMinRatingSection;

  /// No description provided for @attractionFilterRatingAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get attractionFilterRatingAny;

  /// No description provided for @attractionFilterDurationSection.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get attractionFilterDurationSection;

  /// No description provided for @attractionFilterDurationShort.
  ///
  /// In en, this message translates to:
  /// **'Short < 2h'**
  String get attractionFilterDurationShort;

  /// No description provided for @attractionFilterDurationMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium 2–5h'**
  String get attractionFilterDurationMedium;

  /// No description provided for @attractionFilterDurationFullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day 5h+'**
  String get attractionFilterDurationFullDay;

  /// No description provided for @attractionFilterDurationMultiDay.
  ///
  /// In en, this message translates to:
  /// **'Multi-day'**
  String get attractionFilterDurationMultiDay;

  /// No description provided for @attractionFilterRangeSection.
  ///
  /// In en, this message translates to:
  /// **'Specific range'**
  String get attractionFilterRangeSection;

  /// No description provided for @attractionFilterRangeValue.
  ///
  /// In en, this message translates to:
  /// **'{min}h – {max}h'**
  String attractionFilterRangeValue(int min, int max);

  /// No description provided for @attractionFilterRangeMinTick.
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get attractionFilterRangeMinTick;

  /// No description provided for @attractionFilterRangeMaxTick.
  ///
  /// In en, this message translates to:
  /// **'12h+'**
  String get attractionFilterRangeMaxTick;

  /// No description provided for @attractionFilterPriceRangeSection.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get attractionFilterPriceRangeSection;

  /// No description provided for @attractionFilterShowSpots.
  ///
  /// In en, this message translates to:
  /// **'Show {count} spots'**
  String attractionFilterShowSpots(int count);

  /// No description provided for @attractionFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get attractionFilterClear;

  /// No description provided for @attractionMinPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get attractionMinPriceLabel;

  /// No description provided for @attractionMaxPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get attractionMaxPriceLabel;

  /// No description provided for @attractionPriceValidationError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get attractionPriceValidationError;

  /// No description provided for @attractionPriceRangeValidationError.
  ///
  /// In en, this message translates to:
  /// **'Max price must be greater than min price'**
  String get attractionPriceRangeValidationError;

  /// No description provided for @attractionHoursUnit.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get attractionHoursUnit;

  /// No description provided for @attractionDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get attractionDaysUnit;

  /// No description provided for @attractionHoursUnitShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get attractionHoursUnitShort;

  /// No description provided for @attractionDaysUnitShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get attractionDaysUnitShort;

  /// No description provided for @attractionMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get attractionMinLabel;

  /// No description provided for @attractionMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get attractionMaxLabel;

  /// No description provided for @attractionDurationValidationError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid duration'**
  String get attractionDurationValidationError;

  /// No description provided for @attractionDurationRangeValidationError.
  ///
  /// In en, this message translates to:
  /// **'Max duration must be greater than min'**
  String get attractionDurationRangeValidationError;

  /// No description provided for @attractionDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load attraction'**
  String get attractionDetailsLoadFailed;

  /// No description provided for @attractionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attraction details'**
  String get attractionDetailsTitle;

  /// No description provided for @attractionMustVisitBadge.
  ///
  /// In en, this message translates to:
  /// **'Must visit'**
  String get attractionMustVisitBadge;

  /// No description provided for @attractionStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get attractionStatRating;

  /// No description provided for @attractionStatDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get attractionStatDuration;

  /// No description provided for @attractionStatPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get attractionStatPrice;

  /// No description provided for @attractionExperienceSection.
  ///
  /// In en, this message translates to:
  /// **'The experience'**
  String get attractionExperienceSection;

  /// No description provided for @attractionExpectSection.
  ///
  /// In en, this message translates to:
  /// **'What to expect'**
  String get attractionExpectSection;

  /// No description provided for @attractionVisitPlanSection.
  ///
  /// In en, this message translates to:
  /// **'Plan your visit'**
  String get attractionVisitPlanSection;

  /// No description provided for @attractionFlyFyTipTitle.
  ///
  /// In en, this message translates to:
  /// **'FlyFy tip'**
  String get attractionFlyFyTipTitle;

  /// No description provided for @attractionVisitDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Time needed'**
  String get attractionVisitDurationLabel;

  /// No description provided for @attractionVisitDurationFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get attractionVisitDurationFlexible;

  /// No description provided for @attractionVisitTicketsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get attractionVisitTicketsLabel;

  /// No description provided for @attractionVisitFreeEntry.
  ///
  /// In en, this message translates to:
  /// **'Free or varies'**
  String get attractionVisitFreeEntry;

  /// No description provided for @attractionVisitBookingRecommended.
  ///
  /// In en, this message translates to:
  /// **'book ahead'**
  String get attractionVisitBookingRecommended;

  /// No description provided for @attractionVisitBestTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get attractionVisitBestTimeLabel;

  /// No description provided for @attractionVisitBestTimeEarlyMorning.
  ///
  /// In en, this message translates to:
  /// **'Early morning'**
  String get attractionVisitBestTimeEarlyMorning;

  /// No description provided for @attractionVisitBestTimeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get attractionVisitBestTimeMorning;

  /// No description provided for @attractionVisitBestTimeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get attractionVisitBestTimeAfternoon;

  /// No description provided for @attractionVisitBestTimeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get attractionVisitBestTimeSunset;

  /// No description provided for @attractionVisitBestTimeAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get attractionVisitBestTimeAnytime;

  /// No description provided for @attractionVisitGoodForLabel.
  ///
  /// In en, this message translates to:
  /// **'Good for'**
  String get attractionVisitGoodForLabel;

  /// No description provided for @attractionVisitAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get attractionVisitAccessLabel;

  /// No description provided for @attractionVisitAccessGood.
  ///
  /// In en, this message translates to:
  /// **'Easy access'**
  String get attractionVisitAccessGood;

  /// No description provided for @attractionVisitAccessLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited access'**
  String get attractionVisitAccessLimited;

  /// No description provided for @attractionVisitAccessUnknown.
  ///
  /// In en, this message translates to:
  /// **'Check locally'**
  String get attractionVisitAccessUnknown;

  /// No description provided for @attractionVisitSafetyLabel.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get attractionVisitSafetyLabel;

  /// No description provided for @attractionVisitSafetyCheckWeather.
  ///
  /// In en, this message translates to:
  /// **'Check weather'**
  String get attractionVisitSafetyCheckWeather;

  /// No description provided for @attractionVisitSafetyBringWater.
  ///
  /// In en, this message translates to:
  /// **'Bring water'**
  String get attractionVisitSafetyBringWater;

  /// No description provided for @attractionVisitSafetyCheckHours.
  ///
  /// In en, this message translates to:
  /// **'Check hours'**
  String get attractionVisitSafetyCheckHours;

  /// No description provided for @attractionVisitAudienceCouples.
  ///
  /// In en, this message translates to:
  /// **'Couples'**
  String get attractionVisitAudienceCouples;

  /// No description provided for @attractionVisitAudienceWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get attractionVisitAudienceWellness;

  /// No description provided for @attractionVisitTipNature.
  ///
  /// In en, this message translates to:
  /// **'Plan transport and weather before you go; guided routes are usually safer and more predictable.'**
  String get attractionVisitTipNature;

  /// No description provided for @attractionVisitTipCulture.
  ///
  /// In en, this message translates to:
  /// **'Come earlier in the day for calmer photos and leave time for nearby cultural stops.'**
  String get attractionVisitTipCulture;

  /// No description provided for @attractionVisitTipDefault.
  ///
  /// In en, this message translates to:
  /// **'Check current hours and combine this stop with nearby activities to avoid losing time in transit.'**
  String get attractionVisitTipDefault;

  /// No description provided for @attractionReviewsSection.
  ///
  /// In en, this message translates to:
  /// **'Explorer\'s voice'**
  String get attractionReviewsSection;

  /// No description provided for @attractionSeeAllReviews.
  ///
  /// In en, this message translates to:
  /// **'See all ({count})'**
  String attractionSeeAllReviews(int count);

  /// No description provided for @attractionNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first!'**
  String get attractionNoReviews;

  /// No description provided for @attractionAddReview.
  ///
  /// In en, this message translates to:
  /// **'Add review'**
  String get attractionAddReview;

  /// No description provided for @attractionReviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your visit'**
  String get attractionReviewSheetTitle;

  /// No description provided for @attractionReviewRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get attractionReviewRatingLabel;

  /// No description provided for @attractionReviewCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get attractionReviewCommentLabel;

  /// No description provided for @attractionReviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'What stood out, what would you recommend, and what should others know?'**
  String get attractionReviewCommentHint;

  /// No description provided for @attractionReviewAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get attractionReviewAddPhoto;

  /// No description provided for @attractionReviewAddVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get attractionReviewAddVideo;

  /// No description provided for @attractionReviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Publish review'**
  String get attractionReviewSubmit;

  /// No description provided for @attractionReviewSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get attractionReviewSubmitting;

  /// No description provided for @attractionReviewMediaLimit.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to {count} files'**
  String attractionReviewMediaLimit(int count);

  /// No description provided for @attractionReviewPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not attach this file'**
  String get attractionReviewPickFailed;

  /// No description provided for @attractionReviewMediaTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large'**
  String get attractionReviewMediaTooLarge;

  /// No description provided for @attractionReviewUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format'**
  String get attractionReviewUnsupportedFormat;

  /// No description provided for @attractionReviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish the review'**
  String get attractionReviewSubmitFailed;

  /// No description provided for @attractionReviewSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Review published'**
  String get attractionReviewSubmitSuccess;

  /// No description provided for @attractionReviewCommentRequired.
  ///
  /// In en, this message translates to:
  /// **'Write a short comment'**
  String get attractionReviewCommentRequired;

  /// No description provided for @attractionReviewRemoveMedia.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get attractionReviewRemoveMedia;

  /// No description provided for @attractionReviewVideoPreview.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get attractionReviewVideoPreview;

  /// No description provided for @attractionFindExcursions.
  ///
  /// In en, this message translates to:
  /// **'Find excursions'**
  String get attractionFindExcursions;

  /// No description provided for @attractionMapLink.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get attractionMapLink;

  /// No description provided for @attractionVerifiedNomad.
  ///
  /// In en, this message translates to:
  /// **'Verified nomad'**
  String get attractionVerifiedNomad;

  /// No description provided for @attractionReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get attractionReviewsTitle;

  /// No description provided for @attractionTravelerFallback.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get attractionTravelerFallback;

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

  /// No description provided for @attractionPriceVaries.
  ///
  /// In en, this message translates to:
  /// **'Price varies'**
  String get attractionPriceVaries;

  /// No description provided for @attractionPriceVariesShort.
  ///
  /// In en, this message translates to:
  /// **'Varies'**
  String get attractionPriceVariesShort;

  /// No description provided for @attractionDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String attractionDurationHours(int hours);

  /// No description provided for @attractionDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String attractionDurationDays(int days);

  /// No description provided for @attractionBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get attractionBackTooltip;

  /// No description provided for @attractionNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get attractionNotificationsTooltip;

  /// No description provided for @attractionBookmarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save attraction'**
  String get attractionBookmarkTooltip;

  /// No description provided for @attractionTagFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Family friendly'**
  String get attractionTagFamilyLabel;

  /// No description provided for @attractionTagFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suitable for all ages'**
  String get attractionTagFamilySubtitle;

  /// No description provided for @attractionTagSunsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Best at sunset'**
  String get attractionTagSunsetLabel;

  /// No description provided for @attractionTagSunsetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stunning twilight views'**
  String get attractionTagSunsetSubtitle;

  /// No description provided for @attractionTagAccessibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get attractionTagAccessibilityLabel;

  /// No description provided for @attractionTagAccessibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair friendly'**
  String get attractionTagAccessibilitySubtitle;

  /// No description provided for @attractionTagDiningLabel.
  ///
  /// In en, this message translates to:
  /// **'Fine dining'**
  String get attractionTagDiningLabel;

  /// No description provided for @attractionTagDiningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gourmet restaurants'**
  String get attractionTagDiningSubtitle;

  /// No description provided for @attractionTagOutdoorLabel.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get attractionTagOutdoorLabel;

  /// No description provided for @attractionTagOutdoorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nature and fresh air'**
  String get attractionTagOutdoorSubtitle;

  /// No description provided for @attractionTagPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo spot'**
  String get attractionTagPhotoLabel;

  /// No description provided for @attractionTagPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Great for memorable shots'**
  String get attractionTagPhotoSubtitle;

  /// No description provided for @attractionTagHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Historic'**
  String get attractionTagHistoryLabel;

  /// No description provided for @attractionTagHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rich cultural heritage'**
  String get attractionTagHistorySubtitle;

  /// No description provided for @attractionTagAdventureLabel.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get attractionTagAdventureLabel;

  /// No description provided for @attractionTagAdventureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active experiences'**
  String get attractionTagAdventureSubtitle;

  /// No description provided for @attractionTagUniqueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unique experience'**
  String get attractionTagUniqueSubtitle;

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
  /// **'Search excursions and experiences'**
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
  /// **'Search country, code, or phone'**
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
  /// **'Search language or code'**
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
  /// **'Verified guide routes will appear here.'**
  String get excursionsEmptySubtitle;

  /// No description provided for @excursionsEmptySearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another destination, category, or excursion name.'**
  String get excursionsEmptySearchSubtitle;

  /// No description provided for @excursionsNoAttractionExcursionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No excursions for this attraction yet'**
  String get excursionsNoAttractionExcursionsTitle;

  /// No description provided for @excursionsNoAttractionExcursionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showing other available excursions. When guides add a route for this attraction, it will appear here.'**
  String get excursionsNoAttractionExcursionsSubtitle;

  /// No description provided for @guidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Guides'**
  String get guidesTitle;

  /// No description provided for @guidesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search guides'**
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

  /// No description provided for @guidesFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get guidesFilterCountryAll;

  /// No description provided for @guidesFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search country, code, or phone'**
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
  /// **'Search language or code'**
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
  /// **'Verified local experts will appear here.'**
  String get guidesEmptySubtitle;

  /// No description provided for @guidesNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No guides found'**
  String get guidesNoResultsTitle;

  /// No description provided for @guidesNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another name, expertise, language, or filter.'**
  String get guidesNoResultsSubtitle;

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
  /// **'Search guides or offers'**
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
  /// **'Search language or code'**
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

  /// No description provided for @excursionBookingConfirmPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay'**
  String get excursionBookingConfirmPay;

  /// No description provided for @excursionBookingSecurePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure payment processed by FlyFy'**
  String get excursionBookingSecurePayment;

  /// No description provided for @excursionBookingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Booking request is ready. Online payment will be connected soon.'**
  String get excursionBookingSubmitted;

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
  /// **'Publish'**
  String get createExcursionSubmit;

  /// No description provided for @createExcursionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get createExcursionSaveChanges;

  /// No description provided for @createExcursionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Excursion published successfully'**
  String get createExcursionSuccess;

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
  /// **'JPG, PNG or WEBP. If you selected an attraction, its photo will be used unless you upload your own.'**
  String get createExcursionCoverUploadHint;

  /// No description provided for @createExcursionSelectedLandmark.
  ///
  /// In en, this message translates to:
  /// **'Attraction'**
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
  /// **'Choose an attraction'**
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
  /// **'You can enter a custom location or choose an attraction from this country.'**
  String get createExcursionManualLocationHint;

  /// No description provided for @createExcursionLocationLockedByAttraction.
  ///
  /// In en, this message translates to:
  /// **'This location comes from the attraction catalog. Change the attraction to edit it.'**
  String get createExcursionLocationLockedByAttraction;

  /// No description provided for @createExcursionAttractionCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Attraction catalog for the selected country'**
  String get createExcursionAttractionCatalogHint;

  /// No description provided for @createExcursionAttractionCatalogSource.
  ///
  /// In en, this message translates to:
  /// **'From the attraction catalog'**
  String get createExcursionAttractionCatalogSource;

  /// No description provided for @createExcursionSingleAttractionMode.
  ///
  /// In en, this message translates to:
  /// **'Single attraction'**
  String get createExcursionSingleAttractionMode;

  /// No description provided for @createExcursionCombinedRouteMode.
  ///
  /// In en, this message translates to:
  /// **'Combined route'**
  String get createExcursionCombinedRouteMode;

  /// No description provided for @createExcursionCombinedRouteMinStopsValidation.
  ///
  /// In en, this message translates to:
  /// **'Add at least {count} attraction stops'**
  String createExcursionCombinedRouteMinStopsValidation(Object count);

  /// No description provided for @createExcursionCombinedRouteMaxStopsValidation.
  ///
  /// In en, this message translates to:
  /// **'Add no more than {count} attraction stops'**
  String createExcursionCombinedRouteMaxStopsValidation(Object count);

  /// No description provided for @createExcursionDuplicateRouteStopValidation.
  ///
  /// In en, this message translates to:
  /// **'This attraction is already in the route.'**
  String get createExcursionDuplicateRouteStopValidation;

  /// No description provided for @excursionSelectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Attraction'**
  String get excursionSelectLocationTitle;

  /// No description provided for @excursionSelectLocationCountrySection.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get excursionSelectLocationCountrySection;

  /// No description provided for @excursionSelectLocationCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
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

  /// No description provided for @excursionSelectLocationAttractionSection.
  ///
  /// In en, this message translates to:
  /// **'Select Attraction'**
  String get excursionSelectLocationAttractionSection;

  /// No description provided for @excursionSelectLocationAttractionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search attractions...'**
  String get excursionSelectLocationAttractionSearchHint;

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
  /// **'Auto-saving progress to your guide profile'**
  String get createExcursionAutosaveHint;

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
  /// **'Search language or code'**
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
  /// **'Visible to everyone in the FlyFy marketplace.'**
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
  /// **'My Stories'**
  String get myStoriesTitle;

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

  /// No description provided for @myExcursionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Excursions'**
  String get myExcursionsTitle;

  /// No description provided for @myExcursionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search excursions, guides, and cities'**
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
  /// **'FlyFy guide'**
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

  /// No description provided for @myExcursionsGuestsChargeMock.
  ///
  /// In en, this message translates to:
  /// **'To pay: {amount}'**
  String myExcursionsGuestsChargeMock(Object amount);

  /// No description provided for @myExcursionsGuestsRefundMock.
  ///
  /// In en, this message translates to:
  /// **'To refund: {amount}'**
  String myExcursionsGuestsRefundMock(Object amount);

  /// No description provided for @myExcursionsGuestsNoPaymentChange.
  ///
  /// In en, this message translates to:
  /// **'Price will not change'**
  String get myExcursionsGuestsNoPaymentChange;

  /// No description provided for @myExcursionsGuestsPaymentMockHint.
  ///
  /// In en, this message translates to:
  /// **'This is a mock settlement for now: real charges or refunds will be connected through the payment service.'**
  String get myExcursionsGuestsPaymentMockHint;

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
  /// **'Total offers'**
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
  /// **'Search offers, guests, cities, and dates'**
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
  /// **'Booked'**
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

  /// No description provided for @excursionReviewSourceAttractionBadge.
  ///
  /// In en, this message translates to:
  /// **'Review based on a visited excursion'**
  String get excursionReviewSourceAttractionBadge;

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

  /// No description provided for @activitiesFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get activitiesFiltersTitle;

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

  /// No description provided for @storyFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get storyFiltersTitle;

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

  /// No description provided for @storyFilterCountryAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get storyFilterCountryAll;

  /// No description provided for @storyFilterCountrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search country, code, or phone'**
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
  /// **'Show {count, plural, =0{0 stories} =1{1 story} other{{count} stories}}'**
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

  /// No description provided for @storyShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the share sheet. Please try again.'**
  String get storyShareFailed;

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

  /// No description provided for @storyCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get storyCountryHint;

  /// No description provided for @storyCityHint.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
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
  /// **'Search stickers'**
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
