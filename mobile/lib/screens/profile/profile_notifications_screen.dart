import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/error_dialog.dart';
import '../../features/notifications/data/notification_api.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import 'profile_style.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key});

  @override
  State<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState
    extends State<ProfileNotificationsScreen> {
  final ProfileApi _profileApi = ProfileApi();
  final NotificationInboxClient _notificationApi = NotificationApi();
  final Set<String> _busyKeys = <String>{};

  late UserSettingsVm _settings;
  NotificationPreferences _preferences = NotificationPreferences.defaults();
  bool _initialized = false;
  bool _preferencesLoading = true;
  bool _preferencesLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final locationProvider = context.read<HomeLocationProvider>();
    if (!locationProvider.isLoaded && !locationProvider.isLoading) {
      unawaited(
        locationProvider.load(
          languageCode: Localizations.localeOf(context).languageCode,
        ),
      );
    }
    final profile = context.read<SessionProvider>().profile;
    final settings = profile?.settings;
    _settings =
        settings ??
        UserSettingsVm(
          userId: '',
          notificationsPushEnabled: true,
          notificationsEmailEnabled: true,
          notificationsSmsEnabled: false,
          marketingEnabled: false,
          darkModeEnabled: false,
        );
    _initialized = true;
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() {
      _preferencesLoading = true;
      _preferencesLoadFailed = false;
    });
    try {
      final preferences = await _notificationApi.getNotificationPreferences();
      if (!mounted) {
        return;
      }
      setState(() {
        _preferences = preferences;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preferencesLoadFailed = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _preferencesLoading = false;
        });
      }
    }
  }

  Future<void> _updateAccountSetting(
    String key,
    UserSettingsVm Function(UserSettingsVm current) nextValue, {
    bool? notificationsEmailEnabled,
    bool? notificationsSmsEnabled,
  }) async {
    if (_busyKeys.contains(key)) {
      return;
    }

    final previous = _settings;
    setState(() {
      _busyKeys.add(key);
      _settings = nextValue(_settings);
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final updated = await _profileApi.updateMeSettings(
        notificationsEmailEnabled: notificationsEmailEnabled,
        notificationsSmsEnabled: notificationsSmsEnabled,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _settings = updated;
      });
      await context.read<SessionProvider>().reloadProfile();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = previous;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileNotificationsSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyKeys.remove(key);
        });
      }
    }
  }

  Future<void> _updateDeliveryPreference(
    String key,
    NotificationPreferences nextPreferences,
    NotificationPreferencesUpdate update,
  ) async {
    if (_busyKeys.contains(key)) {
      return;
    }

    final previous = _preferences;
    setState(() {
      _busyKeys.add(key);
      _preferences = nextPreferences;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final updated = await _notificationApi.updateNotificationPreferences(
        update,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _preferences = updated;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preferences = previous;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileNotificationsSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyKeys.remove(key);
        });
      }
    }
  }

  Future<void> _updatePushEnabled(bool value) async {
    if (_busyKeys.contains('push')) {
      return;
    }

    final previousSettings = _settings;
    final previousPreferences = _preferences;
    setState(() {
      _busyKeys.add('push');
      _settings = _settings.copyWith(notificationsPushEnabled: value);
      _preferences = _preferences.copyWith(pushEnabled: value);
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final updatedPreferences = await _notificationApi
          .updateNotificationPreferences(
            NotificationPreferencesUpdate(pushEnabled: value),
          );
      final updatedSettings = await _profileApi.updateMeSettings(
        notificationsPushEnabled: value,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _preferences = updatedPreferences;
        _settings = updatedSettings;
      });
      await context.read<SessionProvider>().reloadProfile();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = previousSettings;
        _preferences = previousPreferences;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileNotificationsSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyKeys.remove('push');
        });
      }
    }
  }

  Future<void> _updateMarketingEnabled(bool value) async {
    if (_busyKeys.contains('marketing')) {
      return;
    }

    final previousSettings = _settings;
    final previousPreferences = _preferences;
    setState(() {
      _busyKeys.add('marketing');
      _settings = _settings.copyWith(marketingEnabled: value);
      _preferences = _preferences.copyWith(marketingEnabled: value);
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final updatedPreferences = await _notificationApi
          .updateNotificationPreferences(
            NotificationPreferencesUpdate(marketingEnabled: value),
          );
      final updatedSettings = await _profileApi.updateMeSettings(
        marketingEnabled: value,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _preferences = updatedPreferences;
        _settings = updatedSettings;
      });
      await context.read<SessionProvider>().reloadProfile();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = previousSettings;
        _preferences = previousPreferences;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileNotificationsSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyKeys.remove('marketing');
        });
      }
    }
  }

  Future<void> _pickQuietHour({required bool start}) async {
    final currentMinutes = start
        ? _preferences.quietHoursStartMinutes
        : _preferences.quietHoursEndMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    final minutes = selected.hour * 60 + selected.minute;
    await _applyQuietHours(
      startMinutes: start ? minutes : _preferences.quietHoursStartMinutes,
      endMinutes: start ? _preferences.quietHoursEndMinutes : minutes,
    );
  }

  Future<void> _applyQuietHours({
    required int startMinutes,
    required int endMinutes,
    bool? enabled,
  }) {
    final nextEnabled = enabled ?? _preferences.quietHoursEnabled;
    final timezone = _effectiveTimezone;
    return _updateDeliveryPreference(
      'quiet-hours',
      _preferences.copyWith(
        quietHoursEnabled: nextEnabled,
        quietHoursStartMinutes: startMinutes,
        quietHoursEndMinutes: endMinutes,
        timezone: timezone,
      ),
      NotificationPreferencesUpdate(
        quietHoursEnabled: nextEnabled,
        quietHoursStartMinutes: startMinutes,
        quietHoursEndMinutes: endMinutes,
        timezone: timezone,
      ),
    );
  }

  String get _effectiveTimezone {
    final locationTimezone = context
        .read<HomeLocationProvider>()
        .effectiveLocation
        .timezone
        ?.trim();
    if (locationTimezone != null && locationTimezone.isNotEmpty) {
      return locationTimezone;
    }
    final preferencesTimezone = _preferences.timezone.trim();
    if (preferencesTimezone.isNotEmpty) {
      return preferencesTimezone;
    }
    return 'UTC';
  }

  bool get _deliveryControlsEnabled {
    return !_preferencesLoading && !_preferencesLoadFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = profileScaled(context, 20, min: 14, max: 20);
    final pushControlsEnabled = _deliveryControlsEnabled;
    final categoryControlsEnabled =
        pushControlsEnabled && _preferences.pushEnabled;

    return Scaffold(
      backgroundColor: AppPalette.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: AppEdgeInsets.fromLTRB(
                padding,
                profileScaled(context, 14, min: 10, max: 18),
                padding,
                profileScaled(context, 28, min: 20, max: 34),
              ),
              children: [
                const _NotificationsTopBar(),
                SizedBox(height: profileScaled(context, 24, min: 18, max: 28)),
                _NotificationsHero(
                  title: l10n.profileNotificationsHeroTitle,
                  subtitle: l10n.profileNotificationsHeroSubtitle,
                  pushEnabled: _preferences.pushEnabled,
                  quietHoursEnabled: _preferences.quietHoursEnabled,
                ),
                if (_preferencesLoading) ...[
                  SizedBox(
                    height: profileScaled(context, 16, min: 12, max: 18),
                  ),
                  const _NotificationLinearLoader(),
                ],
                if (_preferencesLoadFailed) ...[
                  SizedBox(
                    height: profileScaled(context, 16, min: 12, max: 18),
                  ),
                  _NotificationInfoBanner(
                    icon: Icons.cloud_off_rounded,
                    title: l10n.profileNotificationsPreferencesLoadFailedTitle,
                    subtitle:
                        l10n.profileNotificationsPreferencesLoadFailedSubtitle,
                    actionLabel: l10n.retry,
                    onAction: _loadNotificationPreferences,
                  ),
                ],
                SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
                ProfileSectionHeading(
                  title: l10n.profileNotificationsDeliverySection,
                ),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _NotificationSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.profileNotificationsPushTitle,
                  subtitle: l10n.profileNotificationsPushSubtitle,
                  value: _preferences.pushEnabled,
                  enabled: pushControlsEnabled && !_busyKeys.contains('push'),
                  busy: _busyKeys.contains('push'),
                  onChanged: _updatePushEnabled,
                ),
                if (!_preferences.pushEnabled)
                  _NotificationInfoBanner(
                    icon: Icons.notifications_paused_rounded,
                    title: l10n.profileNotificationsPushPausedTitle,
                    subtitle: l10n.profileNotificationsPushPausedSubtitle,
                  ),
                SizedBox(height: profileScaled(context, 20, min: 16, max: 24)),
                ProfileSectionHeading(
                  title: l10n.profileNotificationsCategoriesSection,
                ),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _NotificationSwitchTile(
                  icon: Icons.groups_2_outlined,
                  title: l10n.profileNotificationsActivityPushTitle,
                  subtitle: l10n.profileNotificationsActivityPushSubtitle,
                  value: _preferences.activityEnabled,
                  enabled:
                      categoryControlsEnabled &&
                      !_busyKeys.contains('activity'),
                  busy: _busyKeys.contains('activity'),
                  onChanged: (value) => _updateDeliveryPreference(
                    'activity',
                    _preferences.copyWith(activityEnabled: value),
                    NotificationPreferencesUpdate(activityEnabled: value),
                  ),
                ),
                _NotificationSwitchTile(
                  icon: Icons.explore_outlined,
                  title: l10n.profileNotificationsExcursionPushTitle,
                  subtitle: l10n.profileNotificationsExcursionPushSubtitle,
                  value: _preferences.excursionEnabled,
                  enabled:
                      categoryControlsEnabled &&
                      !_busyKeys.contains('excursion'),
                  busy: _busyKeys.contains('excursion'),
                  onChanged: (value) => _updateDeliveryPreference(
                    'excursion',
                    _preferences.copyWith(excursionEnabled: value),
                    NotificationPreferencesUpdate(excursionEnabled: value),
                  ),
                ),
                _NotificationSwitchTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: l10n.profileNotificationsChatPushTitle,
                  subtitle: l10n.profileNotificationsChatPushSubtitle,
                  value: _preferences.chatEnabled,
                  enabled:
                      categoryControlsEnabled && !_busyKeys.contains('chat'),
                  busy: _busyKeys.contains('chat'),
                  onChanged: (value) => _updateDeliveryPreference(
                    'chat',
                    _preferences.copyWith(chatEnabled: value),
                    NotificationPreferencesUpdate(chatEnabled: value),
                  ),
                ),
                _NotificationSwitchTile(
                  icon: Icons.local_offer_outlined,
                  title: l10n.profileNotificationsMarketingTitle,
                  subtitle: l10n.profileNotificationsMarketingSubtitle,
                  value: _preferences.marketingEnabled,
                  enabled:
                      categoryControlsEnabled &&
                      !_busyKeys.contains('marketing'),
                  busy: _busyKeys.contains('marketing'),
                  onChanged: _updateMarketingEnabled,
                ),
                _NotificationInfoBanner(
                  icon: Icons.verified_user_outlined,
                  title: l10n.profileNotificationsSystemTitle,
                  subtitle: l10n.profileNotificationsSystemSubtitle,
                ),
                SizedBox(height: profileScaled(context, 20, min: 16, max: 24)),
                ProfileSectionHeading(
                  title: l10n.profileNotificationsQuietHoursSection,
                ),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _NotificationSwitchTile(
                  icon: Icons.bedtime_outlined,
                  title: l10n.profileNotificationsQuietHoursTitle,
                  subtitle: l10n.profileNotificationsQuietHoursSubtitle(
                    _formatMinutes(
                      context,
                      _preferences.quietHoursStartMinutes,
                    ),
                    _formatMinutes(context, _preferences.quietHoursEndMinutes),
                  ),
                  value: _preferences.quietHoursEnabled,
                  enabled:
                      pushControlsEnabled &&
                      _preferences.pushEnabled &&
                      !_busyKeys.contains('quiet-hours'),
                  busy: _busyKeys.contains('quiet-hours'),
                  onChanged: (value) => _applyQuietHours(
                    startMinutes: _preferences.quietHoursStartMinutes,
                    endMinutes: _preferences.quietHoursEndMinutes,
                    enabled: value,
                  ),
                ),
                _QuietHoursPanel(
                  enabled:
                      pushControlsEnabled &&
                      _preferences.pushEnabled &&
                      !_busyKeys.contains('quiet-hours'),
                  startLabel: _formatMinutes(
                    context,
                    _preferences.quietHoursStartMinutes,
                  ),
                  endLabel: _formatMinutes(
                    context,
                    _preferences.quietHoursEndMinutes,
                  ),
                  timezone: _effectiveTimezone,
                  onStartTap: () => _pickQuietHour(start: true),
                  onEndTap: () => _pickQuietHour(start: false),
                  onPresetSelected: (start, end) => _applyQuietHours(
                    startMinutes: start,
                    endMinutes: end,
                    enabled: true,
                  ),
                ),
                SizedBox(height: profileScaled(context, 20, min: 16, max: 24)),
                ProfileSectionHeading(
                  title: l10n.profileNotificationsChannelsSection,
                ),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _NotificationSwitchTile(
                  icon: Icons.mail_outline_rounded,
                  title: l10n.profileNotificationsEmailTitle,
                  subtitle: l10n.profileNotificationsEmailSubtitle,
                  value: _settings.notificationsEmailEnabled,
                  enabled: !_busyKeys.contains('email'),
                  busy: _busyKeys.contains('email'),
                  onChanged: (value) => _updateAccountSetting(
                    'email',
                    (current) =>
                        current.copyWith(notificationsEmailEnabled: value),
                    notificationsEmailEnabled: value,
                  ),
                ),
                _NotificationSwitchTile(
                  icon: Icons.sms_outlined,
                  title: l10n.profileNotificationsSmsTitle,
                  subtitle: l10n.profileNotificationsSmsSubtitle,
                  value: _settings.notificationsSmsEnabled,
                  enabled: !_busyKeys.contains('sms'),
                  busy: _busyKeys.contains('sms'),
                  onChanged: (value) => _updateAccountSetting(
                    'sms',
                    (current) =>
                        current.copyWith(notificationsSmsEnabled: value),
                    notificationsSmsEnabled: value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsTopBar extends StatelessWidget {
  const _NotificationsTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileTopIconButton(
          icon: Icons.arrow_back,
          onTap: () => context.pop(),
        ),
        Expanded(
          child: Padding(
            padding: AppEdgeInsets.symmetric(
              horizontal: profileScaled(context, 12, min: 8, max: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.profileNotificationsPageTitle,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: AppPalette.textPrimary,
                fontSize: profileScaled(context, 18, min: 16, max: 20),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(width: profileScaled(context, 38, min: 34, max: 40)),
      ],
    );
  }
}

class _NotificationsHero extends StatelessWidget {
  const _NotificationsHero({
    required this.title,
    required this.subtitle,
    required this.pushEnabled,
    required this.quietHoursEnabled,
  });

  final String title;
  final String subtitle;
  final bool pushEnabled;
  final bool quietHoursEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 22, min: 18, max: 24)),
      decoration: profileCardDecoration(
        context,
        highlighted: true,
        radius: profileScaled(context, 28, min: 22, max: 30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: profileScaled(context, 54, min: 48, max: 58),
            height: profileScaled(context, 54, min: 48, max: 58),
            decoration: AppBoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.14),
              borderRadius: AppBorderRadius.circular(
                profileScaled(context, 18, min: 14, max: 20),
              ),
            ),
            child: Icon(
              pushEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_paused_outlined,
              color: AppPalette.primary,
              size: profileScaled(context, 26, min: 22, max: 28),
            ),
          ),
          SizedBox(width: profileScaled(context, 16, min: 12, max: 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: profileScaled(context, 20, min: 18, max: 22),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
                Text(
                  subtitle,
                  style: AppTextStyle(
                    color: profileTextSoft,
                    fontSize: profileScaled(context, 14, min: 13, max: 15),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(
                      label: pushEnabled
                          ? l10n.profileNotificationsPushEnabledStatus
                          : l10n.profileNotificationsPushPausedStatus,
                      active: pushEnabled,
                    ),
                    _StatusPill(
                      label: quietHoursEnabled
                          ? l10n.profileNotificationsQuietHoursEnabledStatus
                          : l10n.profileNotificationsQuietHoursDisabledStatus,
                      active: quietHoursEnabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onChanged == null;
    return Padding(
      padding: AppEdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      child: Container(
        padding: AppEdgeInsets.all(
          profileScaled(context, 18, min: 14, max: 20),
        ),
        decoration: profileCardDecoration(
          context,
          disabled: disabled,
          radius: profileScaled(context, 22, min: 18, max: 24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: profileScaled(context, 46, min: 40, max: 48),
              height: profileScaled(context, 46, min: 40, max: 48),
              decoration: AppBoxDecoration(
                color: AppPalette.primary.withValues(
                  alpha: disabled ? 0.05 : 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: disabled ? profileDisabled : AppPalette.primary,
              ),
            ),
            SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle(
                      color: disabled
                          ? profileDisabled
                          : AppPalette.textPrimary,
                      fontSize: profileScaled(context, 16, min: 14, max: 17),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                  Text(
                    subtitle,
                    style: AppTextStyle(
                      color: disabled ? profileDisabled : profileTextMuted,
                      fontSize: profileScaled(context, 13, min: 12, max: 13),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: profileScaled(context, 12, min: 8, max: 12)),
            if (busy)
              SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppPalette.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              )
            else
              Switch.adaptive(
                value: value,
                onChanged: disabled ? null : onChanged,
                activeThumbColor: AppPalette.primary,
                activeTrackColor: AppPalette.primary.withValues(alpha: 0.38),
                inactiveTrackColor: AppPalette.white.withValues(alpha: 0.1),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuietHoursPanel extends StatelessWidget {
  const _QuietHoursPanel({
    required this.enabled,
    required this.startLabel,
    required this.endLabel,
    required this.timezone,
    required this.onStartTap,
    required this.onEndTap,
    required this.onPresetSelected,
  });

  final bool enabled;
  final String startLabel;
  final String endLabel;
  final String timezone;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final void Function(int startMinutes, int endMinutes) onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final presets = <({String label, int start, int end})>[
      (label: '22:00-08:00', start: 22 * 60, end: 8 * 60),
      (label: '23:00-07:00', start: 23 * 60, end: 7 * 60),
      (label: '00:00-06:00', start: 0, end: 6 * 60),
    ];

    return Container(
      margin: AppEdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      padding: AppEdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
      decoration: profileCardDecoration(
        context,
        disabled: !enabled,
        radius: profileScaled(context, 22, min: 18, max: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TimeButton(
                label: l10n.profileNotificationsQuietHoursStart,
                value: startLabel,
                enabled: enabled,
                onTap: onStartTap,
              ),
              _TimeButton(
                label: l10n.profileNotificationsQuietHoursEnd,
                value: endLabel,
                enabled: enabled,
                onTap: onEndTap,
              ),
            ],
          ),
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          Text(
            l10n.profileNotificationsQuietHoursTimezone(timezone),
            style: AppTextStyle(
              color: enabled ? profileTextMuted : profileDisabled,
              fontSize: profileScaled(context, 12, min: 11, max: 13),
              height: 1.35,
            ),
          ),
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in presets)
                _PresetChip(
                  label: preset.label,
                  enabled: enabled,
                  onTap: () => onPresetSelected(preset.start, preset.end),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppBorderRadius.circular(18),
        child: Ink(
          padding: const AppEdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: AppBoxDecoration(
            color: AppPalette.white.withValues(alpha: enabled ? 0.06 : 0.03),
            borderRadius: AppBorderRadius.circular(18),
            border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyle(
                  color: enabled ? profileTextMuted : profileDisabled,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: AppTextStyle(
                  color: enabled ? AppPalette.textPrimary : profileDisabled,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: enabled ? onTap : null,
      label: Text(label),
      labelStyle: AppTextStyle(
        color: enabled ? AppPalette.textPrimary : profileDisabled,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: AppPalette.white.withValues(alpha: 0.06),
      disabledColor: AppPalette.white.withValues(alpha: 0.03),
      side: BorderSide(color: AppPalette.white.withValues(alpha: 0.08)),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.circular(999),
      ),
    );
  }
}

class _NotificationInfoBanner extends StatelessWidget {
  const _NotificationInfoBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppEdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      padding: AppEdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 22, min: 18, max: 24),
        ),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppPalette.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: AppTextStyle(
                    color: profileTextMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: AppPalette.primary,
                      padding: AppEdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppPalette.primary : AppPalette.textCaption;
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: color.withValues(alpha: active ? 0.14 : 0.10),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.28 : 0.18),
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: AppTextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NotificationLinearLoader extends StatelessWidget {
  const _NotificationLinearLoader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppBorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 3,
        color: AppPalette.primary,
        backgroundColor: AppPalette.white.withValues(alpha: 0.08),
      ),
    );
  }
}

String _formatMinutes(BuildContext context, int minutes) {
  final normalized = minutes.clamp(0, (24 * 60) - 1);
  final time = TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(time, alwaysUse24HourFormat: true);
}
