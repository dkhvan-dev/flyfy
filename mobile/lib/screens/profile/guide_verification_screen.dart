import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/network/reference_api.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/guide_application_vm.dart';
import '../../features/profile/models/update_profile_request.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/profile/models/submit_guide_application_request.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import 'profile_style.dart';

enum _GuideVerificationStep { identity, identityDocument, professional, review }

enum _GuideDocumentKind { identity, professional, firstAid, language }

final class _GuideVerificationColors {
  const _GuideVerificationColors._(this.colors);

  final AppColors colors;

  static _GuideVerificationColors of(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return _GuideVerificationColors._(colors);
  }

  Color get primary => colors.primary;
  Color get primaryPressed => colors.primaryPressed;
  Color get primarySoft => colors.primarySoft;
  Color get primaryContainer => colors.primaryContainer;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;
  Color get textDisabled => colors.textDisabled;
  Color get background => colors.background;
  Color get backgroundWarm => colors.backgroundWarm;
  Color get surface => colors.surface;
  Color get surfaceRaised => colors.surfaceRaised;
  Color get surfaceHigh => colors.surfaceHigh;
  Color get surfaceWarm => colors.surfaceWarm;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get danger => colors.danger;
  Color get transparent => colors.transparent;
  Color get black => colors.black;
  Color get white => colors.white;

  Color get inputFill => colors.surfaceRaised;
  Color get heroOverlayInk => colors.black;
  Color get accentIcon => colors.white;

  List<Color> get amberHeroGradientColors => [
    colors.warning,
    colors.primary,
    colors.primaryContainer,
  ];

  List<Color> get excursionAmberStatusGradientColors => [
    colors.primarySoft,
    colors.primary,
    colors.primaryPressed,
    colors.primary,
  ];
}

extension _GuideVerificationColorContext on BuildContext {
  _GuideVerificationColors get guideColors => _GuideVerificationColors.of(this);
}

class GuideVerificationScreen extends StatefulWidget {
  const GuideVerificationScreen({super.key});

  @override
  State<GuideVerificationScreen> createState() =>
      _GuideVerificationScreenState();
}

class _GuideVerificationScreenState extends State<GuideVerificationScreen> {
  static const String _defaultGuideType = 'INDEPENDENT';
  static const _guideDocumentTypeGroups = [
    file_selector.XTypeGroup(
      label: 'Guide documents',
      extensions: ['jpg', 'jpeg', 'png', 'pdf'],
      mimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
      uniformTypeIdentifiers: ['public.jpeg', 'public.png', 'com.adobe.pdf'],
    ),
  ];

  final GuideApi _guideApi = GuideApi();
  final ProfileApi _profileApi = ProfileApi();
  final FileApi _fileApi = FileApi();

  late final TextEditingController _fullNameController;
  late final TextEditingController _birthDateController;

  // Keys for scrolling to first validation error
  final _fullNameKey = GlobalKey();
  final _birthDateKey = GlobalKey();
  final _countryKey = GlobalKey();
  final _identityDocumentKey = GlobalKey();
  final _identityConfirmKey = GlobalKey();
  final _professionalDocumentKey = GlobalKey();
  final _professionalConfirmKey = GlobalKey();
  final _termsKey = GlobalKey();

  _GuideVerificationStep _step = _GuideVerificationStep.identity;
  GuideApplicationVm? _application;
  bool _isLoading = true;
  bool _isSubmitting = false;

  DateTime? _birthDate;
  String? _countryCode;

  String _identityDocumentType = 'PASSPORT';
  String _professionalDocumentType = 'OFFICIAL_EXCURSION_GUIDE_LICENSE';

  _UploadedGuideDocument _identityDocument = const _UploadedGuideDocument();
  _UploadedGuideDocument _professionalDocument = const _UploadedGuideDocument();
  _UploadedGuideDocument _firstAidDocument = const _UploadedGuideDocument();
  _UploadedGuideDocument _languageCertificateDocument =
      const _UploadedGuideDocument();
  bool _isFirstAidExpanded = false;
  bool _isLanguageCertificateExpanded = false;

  bool _identityConfirmed = false;
  bool _professionalConfirmed = false;
  bool _termsAccepted = false;

  String? _fullNameError;
  String? _birthDateError;
  String? _countryError;
  String? _identityDocumentError;
  String? _identityConfirmError;
  String? _professionalDocumentError;
  String? _professionalConfirmError;
  String? _termsError;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SessionProvider>().profile;
    _fullNameController = TextEditingController(text: _composeFullName(profile))
      ..addListener(() {
        if (_fullNameError != null && mounted) {
          setState(() => _fullNameError = null);
        }
      });
    _birthDate = profile?.birthDate;
    _birthDateController =
        TextEditingController(
          text: _birthDate == null ? '' : _formatBirthDate(_birthDate!),
        )..addListener(() {
          _birthDate = _tryParseBirthDate(_birthDateController.text);
          if (_birthDateError != null && mounted) {
            setState(() => _birthDateError = null);
          }
        });
    _countryCode = _normalizeCountryCode(profile?.countryCode) ?? 'KZ';
    _loadExistingApplication();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingApplication() async {
    try {
      final application = await _guideApi.getMyGuideApplicationOrNull();
      if (!mounted) return;

      if (application != null) {
        final identityDoc = application.documents
            .cast<GuideVerificationDocumentVm?>()
            .firstWhere(
              (item) =>
                  item != null && _isIdentityDocumentType(item.documentType),
              orElse: () => null,
            );
        final professionalDoc = application.documents
            .cast<GuideVerificationDocumentVm?>()
            .firstWhere(
              (item) =>
                  item != null &&
                  _isPrimaryProfessionalDocumentType(item.documentType),
              orElse: () => null,
            );
        final firstAidDoc = application.documents
            .cast<GuideVerificationDocumentVm?>()
            .firstWhere(
              (item) =>
                  item != null && _isFirstAidDocumentType(item.documentType),
              orElse: () => null,
            );
        final languageDoc = application.documents
            .cast<GuideVerificationDocumentVm?>()
            .firstWhere(
              (item) =>
                  item != null &&
                  _isLanguageCertificateDocumentType(item.documentType),
              orElse: () => null,
            );

        setState(() {
          _application = application;
          _identityDocumentType =
              identityDoc?.documentType.trim().isNotEmpty == true
              ? identityDoc!.documentType
              : _identityDocumentType;
          _professionalDocumentType =
              professionalDoc?.documentType.trim().isNotEmpty == true
              ? professionalDoc!.documentType
              : _professionalDocumentType;
          _identityDocument = _identityDocument.copyWith(
            fileId: identityDoc?.fileId,
            name: identityDoc == null
                ? null
                : _documentLabel(identityDoc.documentType),
          );
          _professionalDocument = _professionalDocument.copyWith(
            fileId: professionalDoc?.fileId,
            name: professionalDoc == null
                ? null
                : _documentLabel(professionalDoc.documentType),
          );
          _firstAidDocument = _firstAidDocument.copyWith(
            fileId: firstAidDoc?.fileId,
            name: firstAidDoc == null
                ? null
                : _documentLabel(firstAidDoc.documentType),
          );
          _languageCertificateDocument = _languageCertificateDocument.copyWith(
            fileId: languageDoc?.fileId,
            name: languageDoc == null
                ? null
                : _documentLabel(languageDoc.documentType),
          );
          _isFirstAidExpanded = firstAidDoc != null;
          _isLanguageCertificateExpanded = languageDoc != null;

          if (_identityDocument.hasFile && _professionalDocument.hasFile) {
            _step = _GuideVerificationStep.review;
          } else if (_identityDocument.hasFile) {
            _step = _GuideVerificationStep.professional;
          } else if (application.profile.isDraft ||
              application.profile.isRejected) {
            _step = _GuideVerificationStep.identityDocument;
          }
        });
      }
    } catch (_) {
      // Keep the flow usable even if the existing draft cannot be loaded.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickGuideDocument(_GuideDocumentKind kind) async {
    final l10n = AppLocalizations.of(context)!;

    final file = await file_selector.openFile(
      acceptedTypeGroups: _guideDocumentTypeGroups,
    );
    if (!mounted || file == null) return;

    final fileName = file.name.trim();
    final fileBytes = await file.readAsBytes();
    if (!mounted) return;
    final extension = _fileExtension(fileName);
    final contentType = _contentTypeForExtension(extension);

    if (fileBytes.isEmpty || contentType == null) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.guideVerificationUnsupportedFormat,
      );
      return;
    }

    setState(() {
      if (kind == _GuideDocumentKind.identity) {
        _identityDocument = _identityDocument.copyWith(
          isUploading: true,
          errorText: null,
        );
        _identityDocumentError = null;
      } else if (kind == _GuideDocumentKind.professional) {
        _professionalDocument = _professionalDocument.copyWith(
          isUploading: true,
          errorText: null,
        );
        _professionalDocumentError = null;
      } else if (kind == _GuideDocumentKind.firstAid) {
        _firstAidDocument = _firstAidDocument.copyWith(
          isUploading: true,
          errorText: null,
        );
      } else {
        _languageCertificateDocument = _languageCertificateDocument.copyWith(
          isUploading: true,
          errorText: null,
        );
      }
    });

    try {
      final upload = await _fileApi.createGuideVerificationUpload(
        originalName: fileName,
        contentType: contentType,
        sizeBytes: fileBytes.length,
      );
      await _fileApi.uploadBinary(
        upload: upload,
        bytes: fileBytes,
        contentType: contentType,
      );
      await _fileApi.completeUpload(upload.fileId);

      if (!mounted) return;

      setState(() {
        final next = _UploadedGuideDocument(
          fileId: upload.fileId,
          name: fileName,
          contentType: contentType,
          bytes: fileBytes,
        );
        if (kind == _GuideDocumentKind.identity) {
          _identityDocument = next;
        } else if (kind == _GuideDocumentKind.professional) {
          _professionalDocument = next;
        } else if (kind == _GuideDocumentKind.firstAid) {
          _firstAidDocument = next;
        } else {
          _languageCertificateDocument = next;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        if (kind == _GuideDocumentKind.identity) {
          _identityDocument = _identityDocument.copyWith(
            isUploading: false,
            errorText: l10n.guideVerificationUploadFailed,
          );
        } else if (kind == _GuideDocumentKind.professional) {
          _professionalDocument = _professionalDocument.copyWith(
            isUploading: false,
            errorText: l10n.guideVerificationUploadFailed,
          );
        } else if (kind == _GuideDocumentKind.firstAid) {
          _firstAidDocument = _firstAidDocument.copyWith(
            isUploading: false,
            errorText: l10n.guideVerificationUploadFailed,
          );
        } else {
          _languageCertificateDocument = _languageCertificateDocument.copyWith(
            isUploading: false,
            errorText: l10n.guideVerificationUploadFailed,
          );
        }
      });

      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.guideVerificationUploadFailed,
      );
    }
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context)!;
    var isValid = true;

    setState(() {
      _fullNameError = null;
      _birthDateError = null;
      _countryError = null;
      _identityDocumentError = null;
      _identityConfirmError = null;
      _professionalDocumentError = null;
      _professionalConfirmError = null;
      _termsError = null;
    });

    switch (_step) {
      case _GuideVerificationStep.identity:
        final fullName = _fullNameController.text.trim();
        final birthDateText = _birthDateController.text.trim();
        final parts = fullName
            .split(RegExp(r'\s+'))
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);
        if (fullName.isEmpty) {
          _fullNameError = l10n.guideVerificationFullNameRequired;
          isValid = false;
        } else if (parts.length < 2) {
          _fullNameError = l10n.guideVerificationFullNameInvalid;
          isValid = false;
        }
        _birthDate = _tryParseBirthDate(birthDateText);
        if (birthDateText.isEmpty) {
          _birthDateError = l10n.guideVerificationBirthDateRequired;
          isValid = false;
        } else if (_birthDate == null) {
          _birthDateError = l10n.guideVerificationBirthDateInvalid;
          isValid = false;
        }
        if ((_countryCode ?? '').trim().isEmpty) {
          _countryError = l10n.guideVerificationNationalityRequired;
          isValid = false;
        }
        break;
      case _GuideVerificationStep.identityDocument:
        if (!_identityDocument.hasFile) {
          _identityDocumentError = l10n.guideVerificationIdentityFileRequired;
          isValid = false;
        }
        if (!_identityConfirmed) {
          _identityConfirmError = l10n.guideVerificationConfirmationRequired;
          isValid = false;
        }
        break;
      case _GuideVerificationStep.professional:
        if (!_professionalDocument.hasFile) {
          _professionalDocumentError =
              l10n.guideVerificationProfessionalFileRequired;
          isValid = false;
        }
        if (!_professionalConfirmed) {
          _professionalConfirmError =
              l10n.guideVerificationConfirmationRequired;
          isValid = false;
        }
        break;
      case _GuideVerificationStep.review:
        if (!_termsAccepted) {
          _termsError = l10n.guideVerificationAgreementRequired;
          isValid = false;
        }
        break;
    }

    if (!isValid && mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToFirstError();
      });
    }
    return isValid;
  }

  void _scrollToFirstError() {
    final keys = switch (_step) {
      _GuideVerificationStep.identity => [
        if (_fullNameError != null) _fullNameKey,
        if (_birthDateError != null) _birthDateKey,
        if (_countryError != null) _countryKey,
      ],
      _GuideVerificationStep.identityDocument => [
        if (_identityDocumentError != null) _identityDocumentKey,
        if (_identityConfirmError != null) _identityConfirmKey,
      ],
      _GuideVerificationStep.professional => [
        if (_professionalDocumentError != null) _professionalDocumentKey,
        if (_professionalConfirmError != null) _professionalConfirmKey,
      ],
      _GuideVerificationStep.review => [if (_termsError != null) _termsKey],
    };

    if (keys.isEmpty) return;
    final firstKey = keys.first;
    final ctx = firstKey.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  Future<void> _continue() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validateCurrentStep()) return;

    if (_step == _GuideVerificationStep.review) {
      await _submitApplication();
      return;
    }

    setState(() {
      _step = _GuideVerificationStep.values[_step.index + 1];
    });
  }

  Future<void> _submitApplication() async {
    final l10n = AppLocalizations.of(context)!;
    final sessionProvider = context.read<SessionProvider>();
    final profile = sessionProvider.profile;
    if (profile == null) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileNotAvailable,
      );
      return;
    }

    final nameParts = _splitFullName(_fullNameController.text.trim());

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _profileApi.updateMeProfile(
        UpdateProfileRequest(
          firstName: nameParts.$1,
          lastName: nameParts.$2,
          nickname: profile.nickname,
          bio: profile.bio,
          birthDate: _birthDate,
          avatarFileId: profile.avatarFileId,
          countryCode: _countryCode,
          locale: profile.locale,
          currency: profile.currency,
        ),
      );

      final application = await _guideApi.submitMyGuideApplication(
        SubmitGuideApplicationRequest(
          type: _defaultGuideType,
          identityDocumentFileId: _identityDocument.fileId!,
          identityDocumentType: _identityDocumentType,
          professionalDocumentFileId: _professionalDocument.fileId!,
          professionalDocumentType: _professionalDocumentType,
          firstAidCertificateFileId: _firstAidDocument.fileId,
          languageCertificateFileId: _languageCertificateDocument.fileId,
        ),
      );

      await sessionProvider.reloadProfile();

      if (!mounted) return;
      setState(() {
        _application = application;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      String message = l10n.guideVerificationSubmitFailed;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final backendError = data['error']?.toString().trim() ?? '';
        if (backendError.isNotEmpty) {
          switch (backendError) {
            case 'guide application is already under review':
              message = l10n.guideVerificationPendingSubtitle;
              break;
            case 'guide profile is already active':
              message = l10n.guideVerificationActiveSubtitle;
              break;
            case 'guide application requires identity and professional documents':
              message = l10n.guideVerificationDocumentsRequired;
              break;
            default:
              message = backendError;
          }
        }
      }

      await showErrorDialog(context, title: l10n.error, message: message);
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.guideVerificationSubmitFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.guideColors.transparent,
        body: ProfileResponsiveScope(
          child: ProfileGlassBackground(
            child: const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    }

    final application = _application;
    final isPending = application?.verificationRequest?.isPending == true;
    final isVerified = application?.profile.isVerified == true;
    final isRevoked = application?.profile.isRevoked == true;

    return Scaffold(
      backgroundColor: context.guideColors.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: isPending
                ? _StatusScreen(
                    title: l10n.guideVerificationPendingTitle,
                    subtitle:
                        application?.verificationRequest?.reviewComment
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? application!.verificationRequest!.reviewComment!
                        : l10n.guideVerificationPendingSubtitle,
                    buttonLabel: l10n.guideVerificationBackToProfile,
                  )
                : isRevoked
                ? _StatusScreen(
                    title: l10n.guideVerificationRevokedTitle,
                    subtitle:
                        application?.profile.statusReason?.trim().isNotEmpty ==
                            true
                        ? l10n.guideVerificationRevokedSubtitleWithReason(
                            application!.profile.statusReason!.trim(),
                          )
                        : l10n.guideVerificationRevokedSubtitle,
                    buttonLabel: l10n.guideVerificationBackToProfile,
                  )
                : isVerified
                ? _StatusScreen(
                    title: l10n.guideVerificationActiveTitle,
                    subtitle: l10n.guideVerificationActiveSubtitle,
                    buttonLabel: l10n.guideVerificationBackToProfile,
                  )
                : _buildWizard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildWizard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = profileScaled(context, 20, min: 14, max: 20);
    final steps = _GuideVerificationStep.values;
    final progress = (_step.index + 1) / steps.length;

    return Column(
      children: [
        Padding(
          padding: AppEdgeInsets.fromLTRB(
            padding,
            profileScaled(context, 12, min: 10, max: 16),
            padding,
            profileScaled(context, 14, min: 12, max: 16),
          ),
          child: Row(
            children: [
              ProfileTopIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  if (_step == _GuideVerificationStep.identity) {
                    context.pop();
                    return;
                  }
                  setState(() {
                    _step = _GuideVerificationStep.values[_step.index - 1];
                  });
                },
              ),
              SizedBox(width: profileScaled(context, 12, min: 10, max: 14)),
              Expanded(
                child: Text(
                  l10n.guideVerificationTitle,
                  style: AppTextStyle(
                    color: context.guideColors.textPrimary,
                    fontSize: profileScaled(context, 22, min: 18, max: 24),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: context.guideColors.white.withValues(alpha: 0.06),
          height: 1,
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: AppEdgeInsets.fromLTRB(
              padding,
              profileScaled(context, 22, min: 18, max: 24),
              padding,
              profileScaled(context, 24, min: 20, max: 30),
            ),
            children: [
              _ProgressMeta(
                stepLabel: l10n.guideVerificationStepCounter(
                  _step.index + 1,
                  steps.length,
                ),
                stageLabel: _stageLabel(context, _step),
                progress: progress,
              ),
              SizedBox(height: profileScaled(context, 24, min: 20, max: 28)),
              switch (_step) {
                _GuideVerificationStep.identity => _buildIdentityStep(context),
                _GuideVerificationStep.identityDocument =>
                  _buildIdentityDocumentStep(context),
                _GuideVerificationStep.professional => _buildProfessionalStep(
                  context,
                ),
                _GuideVerificationStep.review => _buildReviewStep(context),
              },
            ],
          ),
        ),
        AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: AppEdgeInsets.fromLTRB(
            padding,
            profileScaled(context, 12, min: 10, max: 14),
            padding,
            MediaQuery.of(context).viewInsets.bottom +
                profileScaled(context, 16, min: 12, max: 18),
          ),
          child: _BottomActionBar(
            label: _ctaLabel(context, _step),
            onPressed: _isSubmitting ? null : _continue,
            busy: _isSubmitting,
            note: _step == _GuideVerificationStep.review
                ? l10n.guideVerificationReviewNote
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroBanner(
          title: l10n.guideVerificationHeroTitle,
          subtitle: l10n.guideVerificationHeroSubtitle,
          variant: _step.index,
        ),
        SizedBox(height: profileScaled(context, 28, min: 22, max: 30)),
        _SectionTitle(
          icon: Icons.fingerprint_rounded,
          title: l10n.guideVerificationIdentitySection,
        ),
        SizedBox(height: profileScaled(context, 16, min: 14, max: 18)),
        _PanelCard(
          child: Column(
            children: [
              _FieldBlock(
                key: _fullNameKey,
                label: l10n.guideVerificationFullNameLabel,
                errorText: _fullNameError,
                child: _DarkInput(
                  controller: _fullNameController,
                  hintText: l10n.guideVerificationFullNameHint,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              SizedBox(height: profileScaled(context, 16, min: 14, max: 18)),
              _FieldBlock(
                key: _birthDateKey,
                label: l10n.guideVerificationBirthDateLabel,
                errorText: _birthDateError,
                child: _DarkInput(
                  controller: _birthDateController,
                  hintText: l10n.guideVerificationBirthDateHint,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [_DateTextInputFormatter()],
                ),
              ),
              SizedBox(height: profileScaled(context, 16, min: 14, max: 18)),
              _FieldBlock(
                key: _countryKey,
                label: l10n.guideVerificationNationalityLabel,
                errorText: _countryError,
                child: _GuideCountrySearchField(
                  countries: _countryOptions,
                  selectedCode: _countryCode,
                  localeCode: localeCode,
                  searchHint: l10n.activitiesFilterCountrySearchHint,
                  noResultsText: l10n.activitiesFilterCountryNoResults,
                  onChanged: (countryCode) {
                    setState(() {
                      _countryCode = countryCode;
                      _countryError = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: profileScaled(context, 18, min: 16, max: 20)),
        _NoticeCard(
          icon: Icons.lock_outline_rounded,
          text: l10n.guideVerificationIdentityNotice,
        ),
      ],
    );
  }

  Widget _buildIdentityDocumentStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressTitle(
          eyebrow: l10n.guideVerificationDocumentTypeLabel,
          title: l10n.guideVerificationUploadPhotoTitle,
          subtitle: l10n.guideVerificationUploadPhotoSubtitle,
        ),
        SizedBox(height: profileScaled(context, 18, min: 16, max: 20)),
        _DarkDropdown(
          label: l10n.guideVerificationDocumentTypeLabel,
          value: _identityDocumentType,
          items: [
            _DropdownItem(
              value: 'PASSPORT',
              label: l10n.guideVerificationPassport,
            ),
            _DropdownItem(
              value: 'NATIONAL_ID',
              label: l10n.guideVerificationNationalId,
            ),
          ],
          onChanged: (value) {
            setState(() {
              _identityDocumentType = value;
            });
          },
        ),
        SizedBox(height: profileScaled(context, 22, min: 18, max: 24)),
        _ResponsiveTipRow(
          first: _TipCard(
            icon: Icons.wb_incandescent_outlined,
            title: l10n.guideVerificationNoGlare,
            subtitle: l10n.guideVerificationNoGlareHint,
          ),
          second: _TipCard(
            icon: Icons.crop_free_rounded,
            title: l10n.guideVerificationFullFrame,
            subtitle: l10n.guideVerificationFullFrameHint,
          ),
        ),
        SizedBox(height: profileScaled(context, 22, min: 18, max: 24)),
        _UploadCard(
          key: _identityDocumentKey,
          icon: Icons.photo_camera_outlined,
          title: _identityDocument.hasFile
              ? (_identityDocument.name ??
                    l10n.guideVerificationTapToCapturePassport)
              : l10n.guideVerificationTapToCapturePassport,
          subtitle: l10n.guideVerificationFileFormatsShort,
          buttonLabel: _guideDocumentButtonLabel(_identityDocument, l10n),
          isUploading: _identityDocument.isUploading,
          onTap: () => _pickGuideDocument(_GuideDocumentKind.identity),
          errorText: _identityDocumentError ?? _identityDocument.errorText,
        ),
        SizedBox(height: profileScaled(context, 18, min: 16, max: 20)),
        _ConfirmCard(
          key: _identityConfirmKey,
          value: _identityConfirmed,
          onChanged: (value) {
            setState(() {
              _identityConfirmed = value;
              _identityConfirmError = null;
            });
          },
          text: l10n.guideVerificationDocumentConfirm,
          errorText: _identityConfirmError,
        ),
      ],
    );
  }

  Widget _buildProfessionalStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressTitle(
          title: l10n.guideVerificationCredentialsTitle,
          subtitle: l10n.guideVerificationCredentialsSubtitle,
        ),
        SizedBox(height: profileScaled(context, 18, min: 16, max: 20)),
        _DarkDropdown(
          label: l10n.guideVerificationLicenseLabel,
          value: _professionalDocumentType,
          items: [
            _DropdownItem(
              value: 'OFFICIAL_EXCURSION_GUIDE_LICENSE',
              label: l10n.guideVerificationOfficialExcursionGuideLicense,
            ),
            _DropdownItem(
              value: 'CITY_GUIDE_PERMIT',
              label: l10n.guideVerificationCityGuidePermit,
            ),
            _DropdownItem(
              value: 'MUSEUM_ACCREDITATION',
              label: l10n.guideVerificationMuseumAccreditation,
            ),
          ],
          onChanged: (value) {
            setState(() {
              _professionalDocumentType = value;
            });
          },
        ),
        SizedBox(height: profileScaled(context, 18, min: 16, max: 22)),
        _UploadCard(
          key: _professionalDocumentKey,
          icon: Icons.cloud_upload_outlined,
          title: _professionalDocument.hasFile
              ? (_professionalDocument.name ??
                    l10n.guideVerificationUploadLicenseTitle)
              : l10n.guideVerificationUploadLicenseTitle,
          subtitle: l10n.guideVerificationUploadLicenseSubtitle,
          buttonLabel: _guideDocumentButtonLabel(_professionalDocument, l10n),
          isUploading: _professionalDocument.isUploading,
          onTap: () => _pickGuideDocument(_GuideDocumentKind.professional),
          errorText:
              _professionalDocumentError ?? _professionalDocument.errorText,
        ),
        SizedBox(height: profileScaled(context, 22, min: 18, max: 24)),
        _SectionHeaderRow(
          title: l10n.guideVerificationAdditionalCertifications,
        ),
        SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
        _OptionalCertificateCard(
          icon: Icons.medical_services_outlined,
          title: l10n.guideVerificationFirstAid,
          subtitle: l10n.guideVerificationFirstAidHint,
          isExpanded: _isFirstAidExpanded,
          isUploaded: _firstAidDocument.hasFile,
          onTap: () {
            setState(() {
              _isFirstAidExpanded = !_isFirstAidExpanded;
            });
          },
        ),
        if (_isFirstAidExpanded) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
          _UploadCard(
            icon: Icons.medical_services_outlined,
            title: _firstAidDocument.hasFile
                ? (_firstAidDocument.name ??
                      l10n.guideVerificationUploadFirstAidTitle)
                : l10n.guideVerificationUploadFirstAidTitle,
            subtitle: l10n.guideVerificationUploadFirstAidSubtitle,
            buttonLabel: _guideDocumentButtonLabel(_firstAidDocument, l10n),
            isUploading: _firstAidDocument.isUploading,
            onTap: () => _pickGuideDocument(_GuideDocumentKind.firstAid),
            errorText: _firstAidDocument.errorText,
          ),
        ],
        SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
        _OptionalCertificateCard(
          icon: Icons.translate_outlined,
          title: l10n.guideVerificationLanguageProficiency,
          subtitle: l10n.guideVerificationLanguageProficiencyHint,
          isExpanded: _isLanguageCertificateExpanded,
          isUploaded: _languageCertificateDocument.hasFile,
          onTap: () {
            setState(() {
              _isLanguageCertificateExpanded = !_isLanguageCertificateExpanded;
            });
          },
        ),
        if (_isLanguageCertificateExpanded) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
          _UploadCard(
            icon: Icons.translate_outlined,
            title: _languageCertificateDocument.hasFile
                ? (_languageCertificateDocument.name ??
                      l10n.guideVerificationUploadLanguageTitle)
                : l10n.guideVerificationUploadLanguageTitle,
            subtitle: l10n.guideVerificationUploadLanguageSubtitle,
            buttonLabel: _guideDocumentButtonLabel(
              _languageCertificateDocument,
              l10n,
            ),
            isUploading: _languageCertificateDocument.isUploading,
            onTap: () => _pickGuideDocument(_GuideDocumentKind.language),
            errorText: _languageCertificateDocument.errorText,
          ),
        ],
        SizedBox(height: profileScaled(context, 18, min: 16, max: 20)),
        _TimelineCard(
          title: l10n.guideVerificationTimelineTitle,
          text: l10n.guideVerificationTimelineText,
        ),
        SizedBox(height: profileScaled(context, 18, min: 16, max: 20)),
        _ConfirmCard(
          key: _professionalConfirmKey,
          value: _professionalConfirmed,
          onChanged: (value) {
            setState(() {
              _professionalConfirmed = value;
              _professionalConfirmError = null;
            });
          },
          text: l10n.guideVerificationDocumentConfirm,
          errorText: _professionalConfirmError,
        ),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroBanner(
          title: l10n.guideVerificationReviewHeroTitle,
          subtitle: l10n.guideVerificationReviewHeroSubtitle,
          variant: _step.index,
          compact: true,
        ),
        SizedBox(height: profileScaled(context, 26, min: 22, max: 30)),
        _SectionHeaderRow(
          title: l10n.guideVerificationReviewTitle,
          actionLabel: l10n.guideVerificationEditInfo,
          onActionTap: () {
            setState(() {
              _step = _GuideVerificationStep.identity;
            });
          },
        ),
        SizedBox(height: profileScaled(context, 16, min: 14, max: 18)),
        _ReviewDocumentCard(
          label: l10n.guideVerificationIdentityDocumentCard,
          title: _documentLabel(_identityDocumentType),
        ),
        SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
        _ReviewDocumentCard(
          label: l10n.guideVerificationProfessionalLicenseCard,
          title: _documentLabel(_professionalDocumentType),
        ),
        if (_firstAidDocument.hasFile) ...[
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          _ReviewDocumentCard(
            label: l10n.guideVerificationFirstAidCertificateCard,
            title: _documentLabel('FIRST_AID_CERTIFICATE'),
          ),
        ],
        if (_languageCertificateDocument.hasFile) ...[
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          _ReviewDocumentCard(
            label: l10n.guideVerificationLanguageCertificateCard,
            title: _documentLabel('LANGUAGE_PROFICIENCY_CERTIFICATE'),
          ),
        ],
        SizedBox(height: profileScaled(context, 24, min: 20, max: 28)),
        _ConfirmCard(
          key: _termsKey,
          value: _termsAccepted,
          onChanged: (value) {
            setState(() {
              _termsAccepted = value;
              _termsError = null;
            });
          },
          text: l10n.guideVerificationAgreement,
          errorText: _termsError,
        ),
      ],
    );
  }

  String _stageLabel(BuildContext context, _GuideVerificationStep step) {
    final l10n = AppLocalizations.of(context)!;
    return switch (step) {
      _GuideVerificationStep.identity => l10n.guideVerificationStepIdentity,
      _GuideVerificationStep.identityDocument =>
        l10n.guideVerificationStepDocument,
      _GuideVerificationStep.professional => l10n.guideVerificationStepLicense,
      _GuideVerificationStep.review => l10n.guideVerificationStepSubmit,
    };
  }

  String _ctaLabel(BuildContext context, _GuideVerificationStep step) {
    final l10n = AppLocalizations.of(context)!;
    return switch (step) {
      _GuideVerificationStep.identity =>
        l10n.guideVerificationContinueToDocuments,
      _GuideVerificationStep.identityDocument =>
        l10n.guideVerificationVerifyContinue,
      _GuideVerificationStep.professional =>
        l10n.guideVerificationVerifyContinue,
      _GuideVerificationStep.review => l10n.guideVerificationSubmit,
    };
  }

  String _formatBirthDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year.toString().padLeft(4, '0')}';
  }

  DateTime? _tryParseBirthDate(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) {
      return null;
    }

    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) {
      return null;
    }
    if (year < 1940 || year > DateTime.now().year) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    if (parsed.isAfter(DateTime.now())) {
      return null;
    }

    return parsed;
  }

  String _composeFullName(UserProfileVm? profile) {
    final first = (profile?.firstName ?? '').trim();
    final last = (profile?.lastName ?? '').trim();
    return [first, last].where((item) => item.isNotEmpty).join(' ');
  }

  (String, String) _splitFullName(String fullName) {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    if (parts.length < 2) {
      return (fullName.trim(), '');
    }

    return (parts.first, parts.sublist(1).join(' '));
  }

  String? _normalizeCountryCode(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _fileExtension(String fileName) {
    final trimmed = fileName.trim();
    final index = trimmed.lastIndexOf('.');
    if (index < 0 || index == trimmed.length - 1) {
      return '';
    }
    return trimmed.substring(index + 1).toLowerCase();
  }

  String? _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }

  bool _isIdentityDocumentType(String value) {
    final normalized = value.trim().toUpperCase();
    return normalized == 'PASSPORT' || normalized == 'NATIONAL_ID';
  }

  bool _isPrimaryProfessionalDocumentType(String value) {
    final normalized = value.trim().toUpperCase();
    return normalized == 'OFFICIAL_EXCURSION_GUIDE_LICENSE' ||
        normalized == 'CITY_GUIDE_PERMIT' ||
        normalized == 'MUSEUM_ACCREDITATION';
  }

  bool _isFirstAidDocumentType(String value) {
    return value.trim().toUpperCase() == 'FIRST_AID_CERTIFICATE';
  }

  bool _isLanguageCertificateDocumentType(String value) {
    return value.trim().toUpperCase() == 'LANGUAGE_PROFICIENCY_CERTIFICATE';
  }

  String _documentLabel(String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value.trim().toUpperCase()) {
      case 'PASSPORT':
        return l10n.guideVerificationPassport;
      case 'NATIONAL_ID':
        return l10n.guideVerificationNationalId;
      case 'CITY_GUIDE_PERMIT':
        return l10n.guideVerificationCityGuidePermit;
      case 'MUSEUM_ACCREDITATION':
        return l10n.guideVerificationMuseumAccreditation;
      case 'FIRST_AID_CERTIFICATE':
        return l10n.guideVerificationFirstAid;
      case 'LANGUAGE_PROFICIENCY_CERTIFICATE':
        return l10n.guideVerificationLanguageProficiency;
      case 'OFFICIAL_EXCURSION_GUIDE_LICENSE':
      default:
        return l10n.guideVerificationOfficialExcursionGuideLicense;
    }
  }
}

String _guideDocumentButtonLabel(
  _UploadedGuideDocument document,
  AppLocalizations l10n,
) {
  return document.hasFile
      ? l10n.guideVerificationReplaceFile
      : l10n.guideVerificationChooseFile;
}

class _UploadedGuideDocument {
  const _UploadedGuideDocument({
    this.fileId,
    this.name,
    this.contentType,
    this.bytes,
    this.isUploading = false,
    this.errorText,
  });

  final String? fileId;
  final String? name;
  final String? contentType;
  final Uint8List? bytes;
  final bool isUploading;
  final String? errorText;

  bool get hasFile => (fileId ?? '').trim().isNotEmpty;

  _UploadedGuideDocument copyWith({
    String? fileId,
    String? name,
    String? contentType,
    Uint8List? bytes,
    bool? isUploading,
    String? errorText,
  }) {
    return _UploadedGuideDocument(
      fileId: fileId ?? this.fileId,
      name: name ?? this.name,
      contentType: contentType ?? this.contentType,
      bytes: bytes ?? this.bytes,
      isUploading: isUploading ?? this.isUploading,
      errorText: errorText,
    );
  }
}

class _GuideCountry {
  const _GuideCountry({
    required this.code,
    required this.ru,
    required this.en,
    required this.kk,
  });

  final String code;
  final String ru;
  final String en;
  final String kk;

  String labelFor(String localeCode) {
    switch (localeCode) {
      case 'kk':
        return kk;
      case 'en':
        return en;
      case 'ru':
      default:
        return ru;
    }
  }
}

const List<_GuideCountry> _countryOptions = [
  _GuideCountry(code: 'KZ', ru: 'Казахстан', en: 'Kazakhstan', kk: 'Қазақстан'),
  _GuideCountry(
    code: 'KG',
    ru: 'Кыргызстан',
    en: 'Kyrgyzstan',
    kk: 'Қырғызстан',
  ),
  _GuideCountry(
    code: 'UZ',
    ru: 'Узбекистан',
    en: 'Uzbekistan',
    kk: 'Өзбекстан',
  ),
  _GuideCountry(code: 'AE', ru: 'ОАЭ', en: 'United Arab Emirates', kk: 'БАӘ'),
  _GuideCountry(code: 'TR', ru: 'Турция', en: 'Turkey', kk: 'Түркия'),
  _GuideCountry(code: 'GE', ru: 'Грузия', en: 'Georgia', kk: 'Грузия'),
  _GuideCountry(code: 'US', ru: 'США', en: 'United States', kk: 'АҚШ'),
  _GuideCountry(
    code: 'GB',
    ru: 'Великобритания',
    en: 'United Kingdom',
    kk: 'Ұлыбритания',
  ),
  _GuideCountry(code: 'DE', ru: 'Германия', en: 'Germany', kk: 'Германия'),
  _GuideCountry(code: 'FR', ru: 'Франция', en: 'France', kk: 'Франция'),
];

BoxDecoration _guideAmberGlassDecoration(
  BuildContext context, {
  bool strong = false,
  double? radius,
}) {
  final effectiveRadius =
      radius ?? profileScaled(context, 22, min: 18, max: 28);
  return AppBoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: strong
          ? [
              context.guideColors.surfaceWarm.withValues(alpha: 0.96),
              context.guideColors.backgroundWarm.withValues(alpha: 0.98),
            ]
          : [
              context.guideColors.primary.withValues(alpha: 0.08),
              context.guideColors.white.withValues(alpha: 0.018),
            ],
    ),
    borderRadius: AppBorderRadius.circular(effectiveRadius),
    border: Border.all(
      color: context.guideColors.primary.withValues(
        alpha: strong ? 0.28 : 0.18,
      ),
    ),
    boxShadow: [
      BoxShadow(
        color: context.guideColors.black.withValues(alpha: 0.26),
        blurRadius: profileScaled(context, 26, min: 18, max: 32),
        offset: Offset(0, profileScaled(context, 12, min: 8, max: 14)),
      ),
      BoxShadow(
        color: context.guideColors.primary.withValues(
          alpha: strong ? 0.18 : 0.1,
        ),
        blurRadius: profileScaled(context, 24, min: 14, max: 30),
        offset: Offset(0, profileScaled(context, 8, min: 4, max: 10)),
      ),
    ],
  );
}

BoxDecoration _guideAmberGradientButtonDecoration(
  BuildContext context, {
  required bool enabled,
}) {
  final radius = AppBorderRadius.circular(999);
  return AppBoxDecoration(
    borderRadius: radius,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: enabled
          ? [context.guideColors.warning, context.guideColors.primary]
          : [
              profileSurfaceMuted.withValues(alpha: 0.84),
              profileSurface.withValues(alpha: 0.84),
            ],
    ),
    border: Border.all(
      color: enabled
          ? context.guideColors.warning.withValues(alpha: 0.58)
          : profileBorderSoft,
    ),
    boxShadow: enabled
        ? [
            BoxShadow(
              color: context.guideColors.primary.withValues(alpha: 0.3),
              blurRadius: profileScaled(context, 28, min: 18, max: 34),
              offset: Offset(0, profileScaled(context, 12, min: 8, max: 14)),
            ),
          ]
        : null,
  );
}

IconData _guideHeroIconForVariant(int variant) {
  switch (variant.clamp(0, 3)) {
    case 0:
      return Icons.workspace_premium_rounded;
    case 1:
      return Icons.badge_outlined;
    case 2:
      return Icons.verified_user_outlined;
    case 3:
    default:
      return Icons.fact_check_outlined;
  }
}

Widget _guideHeroAccentIcon(BuildContext context, IconData icon) {
  return Container(
    width: profileScaled(context, 58, min: 48, max: 64),
    height: profileScaled(context, 58, min: 48, max: 64),
    decoration: AppBoxDecoration(
      borderRadius: AppBorderRadius.circular(
        profileScaled(context, 18, min: 16, max: 20),
      ),
      color: context.guideColors.white.withValues(alpha: 0.13),
      border: Border.all(
        color: context.guideColors.white.withValues(alpha: 0.22),
      ),
    ),
    child: Icon(
      icon,
      color: context.guideColors.accentIcon,
      size: profileScaled(context, 28, min: 24, max: 32),
    ),
  );
}

class _ProgressMeta extends StatelessWidget {
  const _ProgressMeta({
    required this.stepLabel,
    required this.stageLabel,
    required this.progress,
  });

  final String stepLabel;
  final String stageLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 14, min: 12, max: 16)),
      decoration: _guideAmberGlassDecoration(context, strong: true),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: AppEdgeInsets.symmetric(
                  horizontal: profileScaled(context, 10, min: 8, max: 12),
                  vertical: profileScaled(context, 6, min: 5, max: 7),
                ),
                decoration: AppBoxDecoration(
                  color: context.guideColors.warning.withValues(alpha: 0.12),
                  borderRadius: AppBorderRadius.circular(999),
                  border: Border.all(
                    color: context.guideColors.warning.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  stepLabel,
                  style: AppTextStyle(
                    color: context.guideColors.warning,
                    fontSize: profileScaled(context, 12, min: 11, max: 12),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(width: profileScaled(context, 12, min: 10, max: 14)),
              Flexible(
                child: Text(
                  stageLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyle(
                    color: profileTextSoft,
                    fontSize: profileScaled(context, 12, min: 11, max: 12),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          ClipRRect(
            borderRadius: AppBorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: profileScaled(context, 8, min: 6, max: 9),
              backgroundColor: context.guideColors.primary.withValues(
                alpha: 0.14,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                context.guideColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.subtitle,
    required this.variant,
    this.compact = false,
    this.gradientColors,
    this.accentColor,
    this.overlayInkColor,
    this.overlayMidAlpha,
    this.overlayEndAlpha,
  });

  final String title;
  final String subtitle;
  final int variant;
  final bool compact;
  final List<Color>? gradientColors;
  final Color? accentColor;
  final Color? overlayInkColor;
  final double? overlayMidAlpha;
  final double? overlayEndAlpha;

  @override
  Widget build(BuildContext context) {
    final minHeight = compact
        ? profileScaled(context, 150, min: 120, max: 170)
        : profileScaled(context, 190, min: 150, max: 230);

    final borderRadius = AppBorderRadius.circular(
      profileScaled(context, 24, min: 18, max: 28),
    );
    final effectiveAccentColor = accentColor ?? context.guideColors.primary;
    final effectiveOverlayInkColor =
        overlayInkColor ?? context.guideColors.heroOverlayInk;
    final effectiveOverlayMidAlpha = overlayMidAlpha ?? 0.16;
    final effectiveOverlayEndAlpha = overlayEndAlpha ?? 0.52;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: AppBoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: effectiveAccentColor.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: effectiveAccentColor.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: context.guideColors.black.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors ?? context.guideColors.amberHeroGradientColors,
          stops: gradientColors == null ? const [0, 0.58, 1] : null,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned(
              top: profileScaled(context, 16, min: 12, max: 18),
              right: profileScaled(context, 16, min: 12, max: 18),
              child: _guideHeroAccentIcon(
                context,
                _guideHeroIconForVariant(variant),
              ),
            ),
            Positioned(
              right: profileScaled(context, -42, min: -48, max: -36),
              bottom: profileScaled(context, -72, min: -82, max: -58),
              child: Transform.rotate(
                angle: -0.28,
                child: Container(
                  width: profileScaled(context, 154, min: 120, max: 176),
                  height: profileScaled(context, 214, min: 172, max: 236),
                  decoration: AppBoxDecoration(
                    borderRadius: AppBorderRadius.circular(
                      profileScaled(context, 42, min: 32, max: 48),
                    ),
                    border: Border.all(
                      color: context.guideColors.white.withValues(alpha: 0.13),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: compact ? 0.42 : 0.48,
                  child: Container(
                    decoration: AppBoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.guideColors.transparent,
                          effectiveOverlayInkColor.withValues(
                            alpha: effectiveOverlayMidAlpha,
                          ),
                          effectiveOverlayInkColor.withValues(
                            alpha: effectiveOverlayEndAlpha,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: AppEdgeInsets.all(
                profileScaled(context, 18, min: 14, max: 20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: compact
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle(
                      color: context.guideColors.white,
                      fontSize: compact
                          ? profileScaled(context, 28, min: 22, max: 32)
                          : profileScaled(context, 32, min: 24, max: 38),
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  SizedBox(height: profileScaled(context, 8, min: 6, max: 10)),
                  Text(
                    subtitle,
                    style: AppTextStyle(
                      color: context.guideColors.white.withValues(alpha: 0.78),
                      fontSize: profileScaled(context, 14, min: 12, max: 15),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: profileScaled(context, 42, min: 36, max: 46),
          height: profileScaled(context, 42, min: 36, max: 46),
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(
              profileScaled(context, 14, min: 12, max: 16),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.guideColors.warning.withValues(alpha: 0.18),
                context.guideColors.primary.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: context.guideColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            color: context.guideColors.warning,
            size: profileScaled(context, 22, min: 19, max: 24),
          ),
        ),
        SizedBox(width: profileScaled(context, 10, min: 8, max: 10)),
        Expanded(
          child: Text(
            title,
            style: AppTextStyle(
              color: context.guideColors.textPrimary,
              fontSize: profileScaled(context, 20, min: 18, max: 22),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressTitle extends StatelessWidget {
  const _ProgressTitle({
    this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((eyebrow ?? '').trim().isNotEmpty)
          Padding(
            padding: AppEdgeInsets.only(
              bottom: profileScaled(context, 10, min: 8, max: 12),
            ),
            child: Text(
              eyebrow!,
              style: AppTextStyle(
                color: context.guideColors.primary,
                fontSize: profileScaled(context, 12, min: 11, max: 12),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
        Text(
          title,
          style: AppTextStyle(
            color: context.guideColors.textPrimary,
            fontSize: profileScaled(context, 30, min: 24, max: 34),
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
            height: 1,
          ),
        ),
        SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
        Text(
          subtitle,
          style: AppTextStyle(
            color: profileTextSoft,
            fontSize: profileScaled(context, 15, min: 14, max: 16),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: _guideAmberGlassDecoration(context, strong: true),
      child: child,
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: profileTextSoft,
            fontSize: profileScaled(context, 12, min: 11, max: 12),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: profileScaled(context, 10, min: 8, max: 10)),
        child,
        if ((errorText ?? '').trim().isNotEmpty)
          Padding(
            padding: AppEdgeInsets.only(
              top: profileScaled(context, 8, min: 6, max: 8),
            ),
            child: Text(
              errorText!,
              style: AppTextStyle(
                color: context.guideColors.danger,
                fontSize: profileScaled(context, 12, min: 11, max: 12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _DarkInput extends StatelessWidget {
  const _DarkInput({
    required this.controller,
    required this.hintText,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final borderRadius = _guideDropdownBorderRadius(context);

    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyle(
        color: context.guideColors.textPrimary,
        fontSize: profileScaled(context, 16, min: 15, max: 17),
        fontWeight: FontWeight.w600,
      ),
      decoration: AppInputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyle(
          color: profileTextMuted.withValues(alpha: 0.72),
          fontSize: profileScaled(context, 15, min: 14, max: 16),
        ),
        filled: true,
        fillColor: context.guideColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: _guideAmberDropdownBorderSide(context),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: _guideAmberDropdownBorderSide(context),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: _guideAmberDropdownBorderSide(context),
        ),
        contentPadding: AppEdgeInsets.symmetric(
          horizontal: profileScaled(context, 18, min: 16, max: 20),
          vertical: profileScaled(context, 18, min: 16, max: 18),
        ),
      ),
    );
  }
}

BorderRadius _guideDropdownBorderRadius(BuildContext context) {
  return AppBorderRadius.circular(profileScaled(context, 18, min: 16, max: 20));
}

BorderSide _guideAmberDropdownBorderSide(BuildContext context) {
  return BorderSide(
    color: context.guideColors.primary.withValues(alpha: 0.34),
    width: 1.6,
  );
}

class _DateTextInputFormatter extends TextInputFormatter {
  const _DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('.');
      }
      buffer.write(truncated[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _GuideCountrySearchField extends StatefulWidget {
  const _GuideCountrySearchField({
    required this.countries,
    required this.selectedCode,
    required this.localeCode,
    required this.searchHint,
    required this.noResultsText,
    required this.onChanged,
  });

  final List<_GuideCountry> countries;
  final String? selectedCode;
  final String localeCode;
  final String searchHint;
  final String noResultsText;
  final ValueChanged<String> onChanged;

  @override
  State<_GuideCountrySearchField> createState() =>
      _GuideCountrySearchFieldState();
}

class _GuideCountrySearchFieldState extends State<_GuideCountrySearchField> {
  late final ReferenceApi _api;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _searchDebounce;
  List<ReferenceCountry> _visibleCountries = const [];
  ReferenceCountry? _selectedReferenceCountry;
  String _countrySearchQuery = '';
  bool _isSearching = false;
  bool _isOpen = false;

  ReferenceCountry? get _selectedCountry {
    final selectedCode = widget.selectedCode?.trim().toUpperCase();
    if (selectedCode == null || selectedCode.isEmpty) return null;
    final selectedReferenceCountry = _selectedReferenceCountry;
    if (selectedReferenceCountry != null &&
        selectedReferenceCountry.code.trim().toUpperCase() == selectedCode) {
      return selectedReferenceCountry;
    }
    for (final country in widget.countries) {
      if (country.code == selectedCode) {
        return ReferenceCountry(
          code: country.code,
          name: country.labelFor(widget.localeCode),
        );
      }
    }
    return null;
  }

  String get _selectedLabel {
    final selectedCountry = _selectedCountry;
    if (selectedCountry == null) return '';
    final name = selectedCountry.name.trim();
    return name.isNotEmpty ? name : selectedCountry.code.trim().toUpperCase();
  }

  List<ReferenceCountry> get _fallbackCountries {
    return widget.countries
        .map(
          (country) => ReferenceCountry(
            code: country.code,
            name: country.labelFor(widget.localeCode),
          ),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _api = ReferenceApi();
    _controller = TextEditingController(text: _selectedLabel)
      ..addListener(_handleSearchChanged);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _GuideCountrySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCode != widget.selectedCode ||
        oldWidget.localeCode != widget.localeCode) {
      if (_selectedReferenceCountry?.code.trim().toUpperCase() !=
          widget.selectedCode?.trim().toUpperCase()) {
        _selectedReferenceCountry = null;
      }
      _syncSelectedLabel();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {
      _isOpen = _focusNode.hasFocus;
    });
    if (!_focusNode.hasFocus) {
      _syncSelectedLabel();
    }
  }

  void _handleSearchChanged() {
    if (!mounted || !_focusNode.hasFocus) return;
    final query = _controller.text.trim();
    if (query == _countrySearchQuery) return;
    _countrySearchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), _runSearch);
    setState(() => _isOpen = true);
  }

  Future<void> _runSearch() async {
    final query = _countrySearchQuery;
    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _visibleCountries = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final countries = await _api.searchCountries(
        query,
        lang: widget.localeCode,
        limit: 24,
      );
      if (!mounted || _countrySearchQuery != query) return;
      setState(() {
        _visibleCountries = countries;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || _countrySearchQuery != query) return;
      setState(() {
        _visibleCountries = const [];
        _isSearching = false;
      });
    }
  }

  void _syncSelectedLabel() {
    final selectedLabel = _selectedLabel;
    if (_controller.text == selectedLabel) return;
    _controller.value = TextEditingValue(
      text: selectedLabel,
      selection: TextSelection.collapsed(offset: selectedLabel.length),
    );
  }

  void _selectCountry(ReferenceCountry country) {
    final nextLabel = country.name.trim().isNotEmpty
        ? country.name.trim()
        : country.code.trim().toUpperCase();
    _controller.value = TextEditingValue(
      text: nextLabel,
      selection: TextSelection.collapsed(offset: nextLabel.length),
    );
    _searchDebounce?.cancel();
    widget.onChanged(country.code.trim().toUpperCase());
    setState(() {
      _selectedReferenceCountry = country;
      _countrySearchQuery = '';
      _visibleCountries = const [];
      _isSearching = false;
      _isOpen = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = _guideDropdownBorderRadius(context);
    final queryHasEnoughText = _countrySearchQuery.trim().length >= 2;
    final displayCountries = queryHasEnoughText
        ? _visibleCountries
        : _fallbackCountries;
    final selectedCode = widget.selectedCode?.trim().toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          cursorColor: context.guideColors.primary,
          textInputAction: TextInputAction.search,
          style: AppTextStyle(
            color: context.guideColors.textPrimary,
            fontSize: profileScaled(context, 16, min: 15, max: 17),
            fontWeight: FontWeight.w700,
          ),
          decoration: AppInputDecoration(
            hintText: widget.searchHint,
            hintStyle: AppTextStyle(
              color: profileTextMuted.withValues(alpha: 0.72),
              fontSize: profileScaled(context, 15, min: 14, max: 16),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.guideColors.primary,
            ),
            suffixIcon: Icon(
              _isOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: profileTextSoft,
            ),
            filled: true,
            fillColor: context.guideColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: _guideAmberDropdownBorderSide(context),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: _guideAmberDropdownBorderSide(context),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: _guideAmberDropdownBorderSide(context),
            ),
            contentPadding: AppEdgeInsets.symmetric(
              horizontal: profileScaled(context, 18, min: 16, max: 20),
              vertical: profileScaled(context, 18, min: 16, max: 18),
            ),
          ),
        ),
        if (_isOpen) ...[
          SizedBox(height: profileScaled(context, 8, min: 6, max: 10)),
          Container(
            constraints: BoxConstraints(
              maxHeight: profileScaled(context, 224, min: 176, max: 260),
            ),
            decoration: AppBoxDecoration(
              color: context.guideColors.inputFill,
              borderRadius: borderRadius,
              border: Border.all(
                color: context.guideColors.primary.withValues(alpha: 0.34),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.guideColors.black.withValues(alpha: 0.22),
                  blurRadius: profileScaled(context, 18, min: 12, max: 24),
                  offset: Offset(
                    0,
                    profileScaled(context, 10, min: 6, max: 12),
                  ),
                ),
              ],
            ),
            child: _isSearching
                ? Padding(
                    padding: AppEdgeInsets.all(
                      profileScaled(context, 16, min: 14, max: 18),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: context.guideColors.primary,
                        ),
                      ),
                    ),
                  )
                : displayCountries.isEmpty
                ? Padding(
                    padding: AppEdgeInsets.all(
                      profileScaled(context, 16, min: 14, max: 18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_circle_rounded,
                          color: context.guideColors.primary,
                          size: 18,
                        ),
                        SizedBox(
                          width: profileScaled(context, 8, min: 6, max: 10),
                        ),
                        Expanded(
                          child: Text(
                            widget.noResultsText,
                            style: AppTextStyle(
                              color: context.guideColors.primary,
                              fontSize: profileScaled(
                                context,
                                13,
                                min: 12,
                                max: 14,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: AppEdgeInsets.symmetric(
                      vertical: profileScaled(context, 6, min: 4, max: 8),
                    ),
                    shrinkWrap: true,
                    itemCount: displayCountries.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: context.guideColors.primary.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final country = displayCountries[index];
                      final isSelected =
                          country.code.trim().toUpperCase() == selectedCode;
                      return InkWell(
                        onTap: () => _selectCountry(country),
                        child: Padding(
                          padding: AppEdgeInsets.symmetric(
                            horizontal: profileScaled(
                              context,
                              16,
                              min: 14,
                              max: 18,
                            ),
                            vertical: profileScaled(
                              context,
                              12,
                              min: 10,
                              max: 14,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  country.name.trim().isNotEmpty
                                      ? country.name.trim()
                                      : country.code.trim().toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: context.guideColors.textPrimary,
                                    fontSize: profileScaled(
                                      context,
                                      15,
                                      min: 14,
                                      max: 16,
                                    ),
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: context.guideColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.guideColors.primary.withValues(alpha: 0.14),
            context.guideColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 20, min: 18, max: 24),
        ),
        border: Border.all(
          color: context.guideColors.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: profileScaled(context, 40, min: 36, max: 44),
            height: profileScaled(context, 40, min: 36, max: 44),
            decoration: AppBoxDecoration(
              color: context.guideColors.warning.withValues(alpha: 0.14),
              borderRadius: AppBorderRadius.circular(14),
              border: Border.all(
                color: context.guideColors.warning.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, color: context.guideColors.warning),
          ),
          SizedBox(width: profileScaled(context, 12, min: 10, max: 14)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle(
                color: profileTextSoft,
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownItem {
  const _DropdownItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _DarkDropdown extends StatelessWidget {
  const _DarkDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<_DropdownItem> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderRadius = _guideDropdownBorderRadius(context);

    return _FieldBlock(
      label: label,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        icon: Icon(Icons.expand_more_rounded, color: profileTextSoft),
        dropdownColor: profileSurfaceSoft,
        style: AppTextStyle(
          color: context.guideColors.textPrimary,
          fontSize: profileScaled(context, 17, min: 15, max: 18),
          fontWeight: FontWeight.w600,
        ),
        decoration: AppInputDecoration(
          filled: true,
          fillColor: context.guideColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: _guideAmberDropdownBorderSide(context),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: _guideAmberDropdownBorderSide(context),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: _guideAmberDropdownBorderSide(context),
          ),
          contentPadding: AppEdgeInsets.symmetric(
            horizontal: profileScaled(context, 18, min: 16, max: 20),
            vertical: profileScaled(context, 18, min: 16, max: 18),
          ),
        ),
        isExpanded: true,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item.value,
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}

class _ResponsiveTipRow extends StatelessWidget {
  const _ResponsiveTipRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 360;

    if (isNarrow) {
      return Column(
        children: [
          first,
          SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
          second,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: first),
          SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
          Expanded(child: second),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: _guideAmberGlassDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: profileScaled(context, 48, min: 42, max: 52),
            height: profileScaled(context, 48, min: 42, max: 52),
            decoration: AppBoxDecoration(
              color: context.guideColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.guideColors.primary),
          ),
          SizedBox(height: profileScaled(context, 16, min: 14, max: 18)),
          Text(
            title,
            style: AppTextStyle(
              color: context.guideColors.textPrimary,
              fontSize: profileScaled(context, 15, min: 14, max: 16),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
          Text(
            subtitle,
            style: AppTextStyle(
              color: profileTextSoft,
              fontSize: profileScaled(context, 13, min: 12, max: 14),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    required this.isUploading,
    this.errorText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool isUploading;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: context.guideColors.transparent,
          child: InkWell(
            onTap: isUploading ? null : onTap,
            borderRadius: AppBorderRadius.circular(
              profileScaled(context, 26, min: 22, max: 28),
            ),
            child: Container(
              width: double.infinity,
              padding: AppEdgeInsets.all(
                profileScaled(context, 24, min: 20, max: 28),
              ),
              decoration: AppBoxDecoration(
                borderRadius: AppBorderRadius.circular(
                  profileScaled(context, 26, min: 22, max: 28),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.guideColors.primary.withValues(alpha: 0.12),
                    context.guideColors.white.withValues(alpha: 0.018),
                  ],
                ),
                border: Border.all(
                  color: context.guideColors.primary.withValues(alpha: 0.34),
                  width: 1.6,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: profileScaled(context, 80, min: 60, max: 96),
                    height: profileScaled(context, 80, min: 60, max: 96),
                    decoration: AppBoxDecoration(
                      color: context.guideColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: isUploading
                        ? Padding(
                            padding: AppEdgeInsets.all(
                              profileScaled(context, 26, min: 20, max: 28),
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: context.guideColors.primary,
                            ),
                          )
                        : Icon(
                            icon,
                            color: context.guideColors.primary,
                            size: profileScaled(context, 32, min: 24, max: 36),
                          ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 18, min: 16, max: 20),
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyle(
                      color: context.guideColors.textPrimary,
                      fontSize: profileScaled(context, 20, min: 17, max: 22),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyle(
                      color: profileTextMuted,
                      fontSize: profileScaled(context, 12, min: 11, max: 12),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 22, min: 18, max: 24),
                  ),
                  FilledButton(
                    onPressed: isUploading ? null : onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.guideColors.primary,
                      foregroundColor: context.guideColors.textPrimary,
                      padding: AppEdgeInsets.symmetric(
                        horizontal: profileScaled(
                          context,
                          28,
                          min: 24,
                          max: 32,
                        ),
                        vertical: profileScaled(context, 14, min: 12, max: 14),
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
        if ((errorText ?? '').trim().isNotEmpty)
          Padding(
            padding: AppEdgeInsets.only(
              top: profileScaled(context, 8, min: 6, max: 8),
            ),
            child: Text(
              errorText!,
              style: AppTextStyle(
                color: context.guideColors.danger,
                fontSize: profileScaled(context, 12, min: 11, max: 12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = (errorText ?? '').trim().isNotEmpty;
    final borderRadius = AppBorderRadius.circular(
      profileScaled(context, 20, min: 18, max: 24),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: context.guideColors.transparent,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: borderRadius,
            child: Container(
              padding: AppEdgeInsets.all(
                profileScaled(context, 18, min: 16, max: 20),
              ),
              decoration: hasError
                  ? AppBoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.guideColors.danger,
                          context.guideColors.danger,
                        ],
                      ),
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: context.guideColors.danger,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.guideColors.black.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: profileScaled(
                            context,
                            24,
                            min: 16,
                            max: 28,
                          ),
                          offset: Offset(
                            0,
                            profileScaled(context, 10, min: 6, max: 12),
                          ),
                        ),
                        BoxShadow(
                          color: context.guideColors.danger,
                          blurRadius: profileScaled(
                            context,
                            20,
                            min: 14,
                            max: 24,
                          ),
                          offset: Offset(
                            0,
                            profileScaled(context, 6, min: 4, max: 8),
                          ),
                        ),
                      ],
                    )
                  : _guideAmberGlassDecoration(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: value,
                    onChanged: (next) => onChanged(next ?? false),
                    activeColor: context.guideColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.circular(8),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: AppEdgeInsets.only(
                        top: profileScaled(context, 6, min: 4, max: 6),
                      ),
                      child: Text(
                        text,
                        style: AppTextStyle(
                          color: context.guideColors.textPrimary,
                          fontSize: profileScaled(
                            context,
                            14,
                            min: 13,
                            max: 15,
                          ),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if ((errorText ?? '').trim().isNotEmpty)
          Padding(
            padding: AppEdgeInsets.only(
              top: profileScaled(context, 8, min: 6, max: 8),
            ),
            child: Text(
              errorText!,
              style: AppTextStyle(
                color: context.guideColors.danger,
                fontSize: profileScaled(context, 12, min: 11, max: 12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyle(
              color: context.guideColors.textPrimary,
              fontSize: profileScaled(context, 24, min: 20, max: 28),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        if ((actionLabel ?? '').trim().isNotEmpty)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: context.guideColors.primary,
              textStyle: AppTextStyle(
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _OptionalCertificateCard extends StatelessWidget {
  const _OptionalCertificateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.isUploaded,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final bool isUploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderRadius = AppBorderRadius.circular(
      profileScaled(context, 18, min: 16, max: 20),
    );

    return Material(
      color: context.guideColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: AppEdgeInsets.all(
            profileScaled(context, 16, min: 14, max: 18),
          ),
          decoration: _guideAmberGlassDecoration(context),
          child: Row(
            children: [
              Container(
                width: profileScaled(context, 42, min: 38, max: 46),
                height: profileScaled(context, 42, min: 38, max: 46),
                decoration: AppBoxDecoration(
                  color: context.guideColors.white.withValues(alpha: 0.06),
                  borderRadius: AppBorderRadius.circular(
                    profileScaled(context, 12, min: 10, max: 12),
                  ),
                ),
                child: Icon(icon, color: context.guideColors.primary),
              ),
              SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle(
                        color: context.guideColors.textPrimary,
                        fontSize: profileScaled(context, 15, min: 14, max: 16),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 4, min: 3, max: 4)),
                    Text(
                      subtitle,
                      style: AppTextStyle(
                        color: profileTextMuted,
                        fontSize: profileScaled(context, 12, min: 11, max: 12),
                        height: 1.4,
                      ),
                    ),
                    if (isUploaded) ...[
                      SizedBox(
                        height: profileScaled(context, 8, min: 6, max: 8),
                      ),
                      Text(
                        l10n.guideVerificationVerifiedUpload,
                        style: AppTextStyle(
                          color: context.guideColors.primary,
                          fontSize: profileScaled(
                            context,
                            12,
                            min: 11,
                            max: 12,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: isUploaded
                    ? context.guideColors.primary
                    : profileTextSoft,
                size: profileScaled(context, 24, min: 22, max: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 18, min: 16, max: 20)),
      decoration: _guideAmberGlassDecoration(context, strong: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_outlined, color: context.guideColors.primary),
          SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle(
                    color: context.guideColors.textPrimary,
                    fontSize: profileScaled(context, 18, min: 16, max: 20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
                Text(
                  text,
                  style: AppTextStyle(
                    color: profileTextSoft,
                    fontSize: profileScaled(context, 14, min: 13, max: 15),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDocumentCard extends StatelessWidget {
  const _ReviewDocumentCard({required this.label, required this.title});

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 14, min: 12, max: 16)),
      decoration: _guideAmberGlassDecoration(context),
      child: Row(
        children: [
          Container(
            width: profileScaled(context, 72, min: 56, max: 86),
            height: profileScaled(context, 72, min: 56, max: 86),
            decoration: AppBoxDecoration(
              borderRadius: AppBorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.guideColors.white.withValues(alpha: 0.09),
                  context.guideColors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Icon(
              Icons.description_outlined,
              color: context.guideColors.primary,
            ),
          ),
          SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyle(
                    color: context.guideColors.primary,
                    fontSize: profileScaled(context, 12, min: 11, max: 12),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
                Text(
                  title,
                  style: AppTextStyle(
                    color: context.guideColors.textPrimary,
                    fontSize: profileScaled(context, 17, min: 15, max: 18),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: profileScaled(context, 10, min: 8, max: 10)),
                Row(
                  children: [
                    Container(
                      width: profileScaled(context, 18, min: 16, max: 18),
                      height: profileScaled(context, 18, min: 16, max: 18),
                      decoration: AppBoxDecoration(
                        color: context.guideColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: context.guideColors.background,
                      ),
                    ),
                    SizedBox(width: profileScaled(context, 8, min: 6, max: 8)),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.guideVerificationVerifiedUpload,
                      style: AppTextStyle(
                        color: profileTextMuted,
                        fontSize: profileScaled(context, 12, min: 11, max: 12),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: profileDisabled,
            size: profileScaled(context, 28, min: 24, max: 30),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.label,
    required this.onPressed,
    required this.busy,
    this.note,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GuideSolidActionButton(label: label, onPressed: onPressed, busy: busy),
        if ((note ?? '').trim().isNotEmpty)
          Padding(
            padding: AppEdgeInsets.only(
              top: profileScaled(context, 12, min: 10, max: 14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: profileDisabled,
                  size: profileScaled(context, 18, min: 16, max: 18),
                ),
                SizedBox(width: profileScaled(context, 8, min: 6, max: 8)),
                Expanded(
                  child: Text(
                    note!,
                    style: AppTextStyle(
                      color: profileDisabled,
                      fontSize: profileScaled(context, 13, min: 12, max: 14),
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GuideSolidActionButton extends StatelessWidget {
  const _GuideSolidActionButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: context.guideColors.primary,
        foregroundColor: context.guideColors.textPrimary,
        minimumSize: Size(
          double.infinity,
          profileScaled(context, 56, min: 50, max: 58),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(
            profileScaled(context, 18, min: 16, max: 20),
          ),
        ),
      ),
      child: busy
          ? SizedBox(
              width: profileScaled(context, 18, min: 16, max: 18),
              height: profileScaled(context, 18, min: 16, max: 18),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.guideColors.textPrimary,
              ),
            )
          : Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                fontSize: profileScaled(context, 15, min: 14, max: 16),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
    );
  }
}

class _AmberGradientButton extends StatelessWidget {
  const _AmberGradientButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final height = profileScaled(context, 60, min: 50, max: 68);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: _guideAmberGradientButtonDecoration(
            context,
            enabled: enabled,
          ),
          child: Material(
            color: context.guideColors.transparent,
            borderRadius: AppBorderRadius.circular(999),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: AppBorderRadius.circular(999),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Padding(
                  padding: AppEdgeInsets.symmetric(
                    horizontal: profileScaled(context, 18, min: 16, max: 20),
                    vertical: profileScaled(context, 14, min: 12, max: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (busy)
                        SizedBox(
                          width: profileScaled(context, 22, min: 20, max: 24),
                          height: profileScaled(context, 22, min: 20, max: 24),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: context.guideColors.white,
                          ),
                        )
                      else ...[
                        Flexible(
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyle(
                              color: context.guideColors.white,
                              fontSize: profileScaled(
                                context,
                                15,
                                min: 14,
                                max: 16,
                              ),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: profileScaled(context, 8, min: 6, max: 8),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: context.guideColors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusScreen extends StatelessWidget {
  const _StatusScreen({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final padding = profileScaled(context, 20, min: 14, max: 20);

    return Column(
      children: [
        Padding(
          padding: AppEdgeInsets.fromLTRB(
            padding,
            profileScaled(context, 12, min: 10, max: 16),
            padding,
            profileScaled(context, 14, min: 12, max: 16),
          ),
          child: Row(
            children: [
              ProfileTopIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
              SizedBox(width: profileScaled(context, 12, min: 10, max: 14)),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.guideVerificationTitle,
                  style: AppTextStyle(
                    color: context.guideColors.textPrimary,
                    fontSize: profileScaled(context, 22, min: 18, max: 24),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: context.guideColors.white.withValues(alpha: 0.06),
          height: 1,
        ),
        Expanded(
          child: Padding(
            padding: AppEdgeInsets.all(padding),
            child: Column(
              children: [
                _HeroBanner(
                  title: title,
                  subtitle: subtitle,
                  variant: 3,
                  gradientColors:
                      context.guideColors.excursionAmberStatusGradientColors,
                  accentColor: context.guideColors.primary,
                  overlayInkColor: context.guideColors.heroOverlayInk,
                  overlayMidAlpha: 0.08,
                  overlayEndAlpha: 0.32,
                ),
                const Spacer(),
                _AmberGradientButton(
                  label: buttonLabel,
                  onPressed: () => context.pop(),
                  busy: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
