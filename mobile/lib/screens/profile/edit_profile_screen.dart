import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/device/device_context_service.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/update_profile_request.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/session_provider.dart';
import 'profile_style.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileApi = ProfileApi();
  final _fileApi = FileApi();
  final _deviceContextService = const DeviceContextService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _currencyController;

  late String _localeCode;
  late bool _isPublic;
  String? _avatarFileId;

  Future<String?>? _avatarFuture;
  Uint8List? _avatarPreviewBytes;
  bool _isSaving = false;
  bool _isResolvingLocation = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();

    final profile = context.read<SessionProvider>().profile;
    final appLocaleCode = context.read<LocaleProvider>().locale.languageCode;

    _firstNameController = TextEditingController(text: profile?.firstName ?? '')
      ..addListener(_handlePreviewChanged);
    _lastNameController = TextEditingController(text: profile?.lastName ?? '')
      ..addListener(_handlePreviewChanged);
    _displayNameController = TextEditingController(
      text: profile?.displayName ?? '',
    )..addListener(_handlePreviewChanged);
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _countryCodeController = TextEditingController(
      text: profile?.countryCode ?? '',
    );
    _timezoneController = TextEditingController(
      text: profile?.timezone ?? 'Asia/Almaty',
    );
    _currencyController = TextEditingController(
      text: profile?.currency ?? 'KZT',
    );

    _localeCode = _normalizeLocaleCode(
      profile?.locale,
      fallback: appLocaleCode,
    );
    _isPublic = profile?.isPublic ?? true;
    _avatarFileId = (profile?.avatarFileId ?? '').trim().isEmpty
        ? null
        : profile!.avatarFileId!.trim();
    _avatarFuture = _loadAvatarUrl(profile?.avatarFileId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillTimezoneFromDevice();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _countryCodeController.dispose();
    _timezoneController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _handlePreviewChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _loadAvatarUrl(String? avatarFileId) async {
    final trimmed = (avatarFileId ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _fileApi.publicContentUrl(trimmed);
  }

  Future<void> _prefillTimezoneFromDevice() async {
    final currentValue = _timezoneController.text.trim();
    final shouldReplace = currentValue.isEmpty || currentValue == 'Asia/Almaty';

    if (!shouldReplace) return;

    final timezone = await _deviceContextService.getLocalTimezone();
    if (!mounted || timezone == null || timezone.trim().isEmpty) return;

    setState(() {
      _timezoneController.text = timezone;
    });
  }

  Future<void> _resolveLocationFromDevice() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion();
      if (!mounted || suggestion == null) return;

      final confirmed = await _showLocationConfirmDialog(suggestion);
      if (!mounted || confirmed != true) return;

      setState(() {
        if ((suggestion.countryCode ?? '').isNotEmpty) {
          _countryCodeController.text = suggestion.countryCode!;
        }
      });
    } catch (e) {
      if (!mounted) return;

      final code = e.toString();
      String message = l10n.locationDetectFailed;

      if (code.contains('location_services_disabled')) {
        message = l10n.locationServicesDisabled;
      } else if (code.contains('location_permission_denied_forever')) {
        message = l10n.locationPermissionDeniedForever;
      } else if (code.contains('location_permission_denied')) {
        message = l10n.locationPermissionDenied;
      }

      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<bool?> _showLocationConfirmDialog(
    DeviceLocationSuggestion suggestion,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final locationText = [
      if ((suggestion.cityName ?? '').isNotEmpty) suggestion.cityName,
      if ((suggestion.countryName ?? '').isNotEmpty) suggestion.countryName,
      if ((suggestion.countryCode ?? '').isNotEmpty) suggestion.countryCode,
    ].whereType<String>().join(', ');

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.useDetectedLocationTitle),
          content: Text(
            locationText.isEmpty
                ? l10n.locationDetectFailed
                : l10n.useDetectedLocationDescription(locationText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.useButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _profileApi.updateMeProfile(
        UpdateProfileRequest(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          displayName: _displayNameController.text,
          bio: _bioController.text,
          avatarFileId: _avatarFileId,
          countryCode: _countryCodeController.text,
          locale: _localeCode,
          timezone: _timezoneController.text,
          currency: _currencyController.text,
          isPublic: _isPublic,
        ),
      );

      if (!mounted) return;

      await localeProvider.setLocale(updated.locale);
      navigator.pop(true);
    } on DioException catch (e) {
      if (!mounted) return;

      String message = l10n.profileSaveFailed;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final backendError = data['error']?.toString();
        if (backendError != null && backendError.trim().isNotEmpty) {
          if (backendError.trim() == 'display name is already taken') {
            message = l10n.profileDisplayNameTaken;
          } else {
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
        message: l10n.profileSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar || _isSaving) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1800,
    );

    if (picked == null || !mounted) {
      return;
    }

    final contentType = _resolveAvatarContentType(picked.name);
    if (contentType == null) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileSettingsAvatarUnsupportedFormat,
      );
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }

    final previousFuture = _avatarFuture;
    final previousAvatarFileId = _avatarFileId;

    setState(() {
      _isUploadingAvatar = true;
      _avatarPreviewBytes = bytes;
    });

    try {
      final upload = await _fileApi.createAvatarUpload(
        originalName: picked.name,
        contentType: contentType,
        sizeBytes: bytes.length,
      );
      await _fileApi.uploadBinary(
        upload: upload,
        bytes: bytes,
        contentType: contentType,
      );
      await _fileApi.completeUpload(upload.fileId);

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarFileId = upload.fileId;
        _avatarPreviewBytes = bytes;
        _avatarFuture = Future<String?>.value(
          _fileApi.publicContentUrl(upload.fileId),
        );
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarPreviewBytes = null;
        _avatarFileId = previousAvatarFileId;
        _avatarFuture = previousFuture;
      });

      var message = l10n.profileSettingsAvatarUploadFailed;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final backendError = data['error']?.toString().trim() ?? '';
        if (backendError.isNotEmpty) {
          message = backendError;
        }
      }

      await showErrorDialog(context, title: l10n.error, message: message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarPreviewBytes = null;
        _avatarFileId = previousAvatarFileId;
        _avatarFuture = previousFuture;
      });

      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileSettingsAvatarUploadFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  String? _resolveAvatarContentType(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return null;
  }

  String _normalizeLocaleCode(String? raw, {String fallback = 'ru'}) {
    const allowed = {'ru', 'en', 'kk'};

    final normalized = (raw ?? '').trim().toLowerCase();
    if (allowed.contains(normalized)) {
      return normalized;
    }

    final fallbackNormalized = fallback.trim().toLowerCase();
    if (allowed.contains(fallbackNormalized)) {
      return fallbackNormalized;
    }

    return 'ru';
  }

  String _previewName(UserProfileVm? profile) {
    final display = _displayNameController.text.trim();
    if (display.isNotEmpty) {
      return display;
    }

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return profile?.preferredName ?? 'FlyFy';
  }

  String _previewInitials(UserProfileVm? profile) {
    final source = _previewName(profile).trim();
    if (source.isEmpty) {
      return profile?.initials ?? 'F';
    }

    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    return parts.first.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<SessionProvider>().profile;
    final padding = profileScaled(context, 20, min: 14, max: 20);
    final previewName = _previewName(profile);
    final previewInitials = _previewInitials(profile);
    final isGuide = profile?.isGuide ?? false;
    final serviceCityChips = [
      if (_countryCodeController.text.trim().isNotEmpty)
        _countryCodeController.text.trim(),
      _timezoneController.text.trim(),
      _currencyController.text.trim(),
      _localeCode.toUpperCase(),
    ].where((item) => item.isNotEmpty).toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  padding,
                  profileScaled(context, 14, min: 10, max: 18),
                  padding,
                  profileScaled(context, 28, min: 20, max: 34),
                ),
                children: [
                  _EditProfileTopBar(title: l10n.profileSettingsPageTitle),
                  SizedBox(
                    height: profileScaled(context, 26, min: 18, max: 30),
                  ),
                  FutureBuilder<String?>(
                    future: _avatarFuture,
                    builder: (context, snapshot) {
                      return _EditProfileHero(
                        avatarUrl: snapshot.data,
                        avatarBytes: _avatarPreviewBytes,
                        initials: previewInitials,
                        name: previewName,
                        phone: profile?.primaryPhone,
                        email: profile?.primaryEmail,
                        avatarHint: _isUploadingAvatar
                            ? l10n.profileSettingsAvatarUploading
                            : l10n.profileSettingsAvatarUploadHint,
                        onAvatarTap: _pickAvatar,
                        isUploadingAvatar: _isUploadingAvatar,
                      );
                    },
                  ),
                  SizedBox(
                    height: profileScaled(context, 32, min: 24, max: 34),
                  ),
                  ProfileSectionHeading(
                    title: l10n.profileSettingsDescriptionSection,
                  ),
                  SizedBox(
                    height: profileScaled(context, 14, min: 12, max: 16),
                  ),
                  _ProfileSectionCard(
                    child: _StyledTextField(
                      controller: _bioController,
                      hintText: l10n.bioLabel,
                      minLines: 4,
                      maxLines: 7,
                    ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  ProfileSectionHeading(
                    title: l10n.profileSettingsDetailsSection,
                  ),
                  SizedBox(
                    height: profileScaled(context, 14, min: 12, max: 16),
                  ),
                  _ProfileSectionCard(
                    child: Column(
                      children: [
                        _LabeledInput(
                          label: l10n.firstNameLabel,
                          child: _StyledTextField(
                            controller: _firstNameController,
                            hintText: l10n.firstNameLabel,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return l10n.firstNameRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.lastNameLabel,
                          child: _StyledTextField(
                            controller: _lastNameController,
                            hintText: l10n.lastNameLabel,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return l10n.lastNameRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.displayNameLabel,
                          child: _StyledTextField(
                            controller: _displayNameController,
                            hintText: l10n.displayNameLabel,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 18, min: 16, max: 20),
                        ),
                        _LabeledInput(
                          label: l10n.appLanguageTitle,
                          child: DropdownButtonFormField<String>(
                            initialValue: _normalizeLocaleCode(_localeCode),
                            dropdownColor: profileSurfaceSoft,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: profileScaled(
                                context,
                                15,
                                min: 14,
                                max: 16,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(
                              profileScaled(context, 18, min: 16, max: 20),
                            ),
                            decoration: _fieldDecoration(context),
                            items: const [
                              DropdownMenuItem(
                                value: 'ru',
                                child: Text('Русский'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English'),
                              ),
                              DropdownMenuItem(
                                value: 'kk',
                                child: Text('Қазақша'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _localeCode = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.profileCountry,
                          child: _StyledTextField(
                            controller: _countryCodeController,
                            hintText: 'KZ',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.profileTimezone,
                          child: _StyledTextField(
                            controller: _timezoneController,
                            hintText: 'Asia/Almaty',
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.profileCurrency,
                          child: _StyledTextField(
                            controller: _currencyController,
                            hintText: 'KZT',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 18, min: 16, max: 20),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isResolvingLocation
                                ? null
                                : _resolveLocationFromDevice,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: BorderSide(
                                color: AppColors.accent.withValues(alpha: 0.2),
                              ),
                              backgroundColor: AppColors.accent.withValues(
                                alpha: 0.05,
                              ),
                              padding: EdgeInsets.symmetric(
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
                                  max: 12,
                                ),
                              ),
                            ),
                            icon: _isResolvingLocation
                                ? SizedBox(
                                    width: profileScaled(
                                      context,
                                      18,
                                      min: 16,
                                      max: 18,
                                    ),
                                    height: profileScaled(
                                      context,
                                      18,
                                      min: 16,
                                      max: 18,
                                    ),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location_outlined),
                            label: Text(l10n.detectLocationButton),
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 18, min: 16, max: 20),
                        ),
                        _VisibilityToggleRow(
                          value: _isPublic,
                          onChanged: (value) {
                            setState(() {
                              _isPublic = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  if (isGuide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ProfileSectionHeading(
                            title: l10n.profileSettingsServiceCitiesSection,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: profileScaled(context, 4, min: 2, max: 4),
                          ),
                          child: Text(
                            l10n.profileSettingsAddNew,
                            style: TextStyle(
                              color: profileDisabled,
                              fontSize: profileScaled(
                                context,
                                12,
                                min: 11,
                                max: 12,
                              ),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: profileScaled(context, 14, min: 12, max: 16),
                    ),
                    _ProfileSectionCard(
                      disabled: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: profileScaled(
                              context,
                              10,
                              min: 8,
                              max: 10,
                            ),
                            runSpacing: profileScaled(
                              context,
                              10,
                              min: 8,
                              max: 10,
                            ),
                            children: [
                              for (final item in serviceCityChips.take(4))
                                _ServiceChip(
                                  text: item,
                                  active: item == serviceCityChips.first,
                                ),
                              _ServiceChip(
                                text: l10n.profileDisabledSoon,
                                active: false,
                                disabled: true,
                              ),
                            ],
                          ),
                          SizedBox(
                            height: profileScaled(
                              context,
                              14,
                              min: 12,
                              max: 16,
                            ),
                          ),
                          Text(
                            l10n.profileSettingsServiceCitiesUnavailable,
                            style: TextStyle(
                              color: profileDisabled,
                              fontSize: profileScaled(
                                context,
                                13,
                                min: 12,
                                max: 13,
                              ),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 28, min: 24, max: 32),
                    ),
                  ],
                  ProfileSectionHeading(
                    title: l10n.profileSettingsSecuritySection,
                  ),
                  SizedBox(
                    height: profileScaled(context, 14, min: 12, max: 16),
                  ),
                  _SecurityLinkCard(
                    title: l10n.profileSettingsSecurityPinTitle,
                    subtitle: l10n.profileSettingsSecurityPinSubtitle,
                    onTap: () => context.push('/profile/security'),
                  ),
                  SizedBox(
                    height: profileScaled(context, 30, min: 24, max: 34),
                  ),
                  FilledButton(
                    onPressed: (_isSaving || _isUploadingAvatar) ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: Size(
                        double.infinity,
                        profileScaled(context, 56, min: 50, max: 58),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          profileScaled(context, 18, min: 16, max: 20),
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: profileScaled(context, 18, min: 16, max: 18),
                            height: profileScaled(
                              context,
                              18,
                              min: 16,
                              max: 18,
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.profileSaveChangesButton,
                            style: TextStyle(
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
                    height: profileScaled(context, 18, min: 14, max: 20),
                  ),
                  Center(
                    child: Text(
                      l10n.profileDeactivateAccountLabel,
                      style: TextStyle(
                        color: Color.fromARGB(255, 143, 34, 15),
                        fontSize: profileScaled(context, 12, min: 11, max: 12),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context) {
    final radius = BorderRadius.circular(
      profileScaled(context, 18, min: 16, max: 20),
    );

    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE47F78)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE47F78)),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 16, min: 14, max: 18),
        vertical: profileScaled(context, 14, min: 12, max: 16),
      ),
    );
  }
}

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileTopIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 12, min: 8, max: 12),
            ),
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.left,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: profileScaled(context, 18, min: 16, max: 20),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileHero extends StatelessWidget {
  const _EditProfileHero({
    required this.avatarUrl,
    required this.avatarBytes,
    required this.initials,
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarHint,
    required this.onAvatarTap,
    required this.isUploadingAvatar,
  });

  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final String initials;
  final String name;
  final String? phone;
  final String? email;
  final String avatarHint;
  final VoidCallback onAvatarTap;
  final bool isUploadingAvatar;

  @override
  Widget build(BuildContext context) {
    final size = profileScaled(context, 118, min: 100, max: 126);

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(
                    profileScaled(context, 4, min: 3, max: 5),
                  ),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE5C48D), Color(0xFF8B5506)],
                    ),
                  ),
                  child: ClipOval(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFEEF3F6), Color(0xFFB9CAD5)],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (avatarBytes != null)
                            Image.memory(avatarBytes!, fit: BoxFit.cover)
                          else if (avatarUrl != null)
                            Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: const Color(0xFF516572),
                                    fontSize: profileScaled(
                                      context,
                                      34,
                                      min: 28,
                                      max: 36,
                                    ),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: const Color(0xFF516572),
                                  fontSize: profileScaled(
                                    context,
                                    34,
                                    min: 28,
                                    max: 36,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (isUploadingAvatar)
                            Container(
                              color: Colors.black.withValues(alpha: 0.28),
                              child: Center(
                                child: SizedBox(
                                  width: profileScaled(
                                    context,
                                    24,
                                    min: 22,
                                    max: 24,
                                  ),
                                  height: profileScaled(
                                    context,
                                    24,
                                    min: 22,
                                    max: 24,
                                  ),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: profileScaled(context, -2, min: -2, max: 0),
                bottom: profileScaled(context, 10, min: 8, max: 12),
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: profileScaled(context, 34, min: 30, max: 36),
                    height: profileScaled(context, 34, min: 30, max: 36),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                      border: Border.all(color: profileBgTop, width: 2),
                    ),
                    child: Icon(
                      isUploadingAvatar
                          ? Icons.hourglass_top_rounded
                          : Icons.edit_rounded,
                      color: Colors.white,
                      size: profileScaled(context, 16, min: 14, max: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: profileScaled(context, 18, min: 14, max: 20)),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: profileScaled(context, 28, min: 24, max: 30),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        if ((phone ?? '').trim().isNotEmpty ||
            (email ?? '').trim().isNotEmpty) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: profileScaled(context, 10, min: 8, max: 10),
            runSpacing: profileScaled(context, 10, min: 8, max: 10),
            children: [
              if ((phone ?? '').trim().isNotEmpty) _ContactPill(text: phone!),
              if ((email ?? '').trim().isNotEmpty) _ContactPill(text: email!),
            ],
          ),
        ],
        SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
        Text(
          avatarHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: profileDisabled,
            fontSize: profileScaled(context, 12, min: 11, max: 12),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 12, min: 10, max: 14),
        vertical: profileScaled(context, 7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: profileTextSoft,
          fontSize: profileScaled(context, 12, min: 11, max: 12),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.child, this.disabled = false});

  final Widget child;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
      decoration: profileCardDecoration(
        context,
        disabled: disabled,
        radius: profileScaled(context, 22, min: 18, max: 24),
      ),
      child: child,
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: profileTextSoft,
            fontSize: profileScaled(context, 12, min: 11, max: 12),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
        child,
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      profileScaled(context, 18, min: 16, max: 20),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: profileScaled(context, 15, min: 14, max: 16),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: profileTextMuted,
          fontSize: profileScaled(context, 15, min: 14, max: 16),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFE47F78)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFE47F78)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: profileScaled(context, 16, min: 14, max: 18),
          vertical: profileScaled(context, 14, min: 12, max: 16),
        ),
      ),
    );
  }
}

class _VisibilityToggleRow extends StatelessWidget {
  const _VisibilityToggleRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(
          profileScaled(context, 18, min: 16, max: 20),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileVisibility,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: profileScaled(context, 15, min: 14, max: 16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: profileScaled(context, 4, min: 4, max: 6)),
                Text(
                  value ? l10n.profilePublic : l10n.profilePrivate,
                  style: TextStyle(
                    color: profileTextMuted,
                    fontSize: profileScaled(context, 13, min: 12, max: 13),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.38),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.text,
    required this.active,
    this.disabled = false,
  });

  final String text;
  final bool active;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? profileDisabled
        : active
        ? AppColors.accent
        : profileTextSoft;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 14, min: 12, max: 16),
        vertical: profileScaled(context, 9, min: 8, max: 10),
      ),
      decoration: BoxDecoration(
        color: disabled
            ? Colors.white.withValues(alpha: 0.03)
            : active
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: disabled
              ? Colors.white.withValues(alpha: 0.04)
              : active
              ? AppColors.accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: profileScaled(context, 12, min: 11, max: 12),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SecurityLinkCard extends StatelessWidget {
  const _SecurityLinkCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        profileScaled(context, 22, min: 18, max: 24),
      ),
      child: Ink(
        padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
        decoration: profileCardDecoration(
          context,
          radius: profileScaled(context, 22, min: 18, max: 24),
        ),
        child: Row(
          children: [
            Container(
              width: profileScaled(context, 48, min: 42, max: 50),
              height: profileScaled(context, 48, min: 42, max: 50),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                  profileScaled(context, 16, min: 14, max: 18),
                ),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.accent,
                size: profileScaled(context, 22, min: 20, max: 24),
              ),
            ),
            SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: profileScaled(context, 16, min: 14, max: 17),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: profileTextMuted,
                      fontSize: profileScaled(context, 13, min: 12, max: 13),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
            Icon(
              Icons.chevron_right_rounded,
              color: profileTextMuted,
              size: profileScaled(context, 24, min: 22, max: 24),
            ),
          ],
        ),
      ),
    );
  }
}
