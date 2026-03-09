import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/device/device_context_service.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/update_profile_request.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/session_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileApi = ProfileApi();
  final _deviceContextService = const DeviceContextService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _currencyController;

  late String _localeCode;
  late bool _isPublic;

  bool _isSaving = false;
  bool _isResolvingLocation = false;

  @override
  void initState() {
    super.initState();

    final profile = context.read<SessionProvider>().profile;
    final appLocaleCode = context.read<LocaleProvider>().locale.languageCode;

    _firstNameController = TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _displayNameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _countryCodeController = TextEditingController(text: profile?.countryCode ?? '');
    _timezoneController = TextEditingController(
      text: profile?.timezone ?? 'Asia/Almaty',
    );
    _currencyController = TextEditingController(text: profile?.currency ?? 'KZT');

    _localeCode = _normalizeLocaleCode(profile?.locale, fallback: appLocaleCode);
    _isPublic = profile?.isPublic ?? true;

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

  Future<void> _prefillTimezoneFromDevice() async {
    final currentValue = _timezoneController.text.trim();
    final shouldReplace =
        currentValue.isEmpty || currentValue == 'Asia/Almaty';

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

      await showErrorDialog(
        context,
        title: l10n.error,
        message: message,
      );
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
          countryCode: _countryCodeController.text,
          locale: _localeCode,
          timezone: _timezoneController.text,
          currency: _currencyController.text,
          isPublic: _isPublic,
        ),
      );

      if (!mounted) return;

      await context.read<LocaleProvider>().setLocale(updated.locale);
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;

      String message = l10n.profileSaveFailed;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final backendError = data['error']?.toString();
        if (backendError != null && backendError.trim().isNotEmpty) {
          message = backendError;
        }
      }

      await showErrorDialog(
        context,
        title: l10n.error,
        message: message,
      );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<SessionProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileButton),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if ((profile?.primaryPhone ?? '').isNotEmpty)
                ListTile(
                  title: Text(l10n.profilePhone),
                  subtitle: Text(profile!.primaryPhone!),
                ),
              if ((profile?.primaryEmail ?? '').isNotEmpty)
                ListTile(
                  title: Text(l10n.profileEmail),
                  subtitle: Text(profile!.primaryEmail!),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: l10n.firstNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.firstNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: l10n.lastNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return l10n.lastNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: l10n.displayNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.bioLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryCodeController,
                decoration: InputDecoration(
                  labelText: l10n.profileCountry,
                  hintText: 'KZ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isResolvingLocation ? null : _resolveLocationFromDevice,
                icon: const Icon(Icons.my_location_outlined),
                label: _isResolvingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.detectLocationButton),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _normalizeLocaleCode(_localeCode),
                decoration: InputDecoration(
                  labelText: l10n.appLanguageTitle,
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ru', child: Text('Русский')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _localeCode = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timezoneController,
                decoration: InputDecoration(
                  labelText: l10n.profileTimezone,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currencyController,
                decoration: InputDecoration(
                  labelText: l10n.profileCurrency,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                title: Text(l10n.profileVisibility),
                subtitle: Text(_isPublic ? l10n.profilePublic : l10n.profilePrivate),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveProfileButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}