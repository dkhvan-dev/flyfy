import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
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
  final Set<String> _busyKeys = <String>{};

  late UserSettingsVm _settings;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final settings = context.read<SessionProvider>().profile?.settings;
    _settings = settings ??
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

  Future<void> _updateSetting(
    String key,
    UserSettingsVm Function(UserSettingsVm current) nextValue, {
    bool? notificationsPushEnabled,
    bool? notificationsEmailEnabled,
    bool? notificationsSmsEnabled,
    bool? marketingEnabled,
    bool? darkModeEnabled,
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
        notificationsPushEnabled: notificationsPushEnabled,
        notificationsEmailEnabled: notificationsEmailEnabled,
        notificationsSmsEnabled: notificationsSmsEnabled,
        marketingEnabled: marketingEnabled,
        darkModeEnabled: darkModeEnabled,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = profileScaled(context, 20, min: 14, max: 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
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
                const _NotificationsTopBar(),
                SizedBox(height: profileScaled(context, 24, min: 18, max: 28)),
                _NotificationsHero(
                  title: l10n.profileNotificationsHeroTitle,
                  subtitle: l10n.profileNotificationsHeroSubtitle,
                ),
                SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
                ProfileSectionHeading(
                  title: l10n.profileNotificationsActivitySection,
                ),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _NotificationSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.profileNotificationsPushTitle,
                  subtitle: l10n.profileNotificationsPushSubtitle,
                  value: _settings.notificationsPushEnabled,
                  enabled: !_busyKeys.contains('push'),
                  onChanged: (value) => _updateSetting(
                    'push',
                    (current) =>
                        current.copyWith(notificationsPushEnabled: value),
                    notificationsPushEnabled: value,
                  ),
                ),
                _NotificationSwitchTile(
                  icon: Icons.mail_outline_rounded,
                  title: l10n.profileNotificationsEmailTitle,
                  subtitle: l10n.profileNotificationsEmailSubtitle,
                  value: _settings.notificationsEmailEnabled,
                  enabled: !_busyKeys.contains('email'),
                  onChanged: (value) => _updateSetting(
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
                  onChanged: (value) => _updateSetting(
                    'sms',
                    (current) =>
                        current.copyWith(notificationsSmsEnabled: value),
                    notificationsSmsEnabled: value,
                  ),
                ),
                SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
                ProfileSectionHeading(
                  title: l10n.profileNotificationsDiscoverySection,
                ),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _NotificationSwitchTile(
                  icon: Icons.local_offer_outlined,
                  title: l10n.profileNotificationsMarketingTitle,
                  subtitle: l10n.profileNotificationsMarketingSubtitle,
                  value: _settings.marketingEnabled,
                  enabled: !_busyKeys.contains('marketing'),
                  onChanged: (value) => _updateSetting(
                    'marketing',
                    (current) => current.copyWith(marketingEnabled: value),
                    marketingEnabled: value,
                  ),
                ),
                _NotificationSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.profileNotificationsDarkModeTitle,
                  subtitle: l10n.profileNotificationsDarkModeSubtitle,
                  value: _settings.darkModeEnabled,
                  enabled: false,
                  onChanged: null,
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
            padding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 12, min: 8, max: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.profileNotificationsPageTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
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
  const _NotificationsHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(profileScaled(context, 22, min: 18, max: 24)),
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
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(
                profileScaled(context, 18, min: 14, max: 20),
              ),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: AppColors.accent,
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: profileScaled(context, 20, min: 18, max: 22),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
                Text(
                  subtitle,
                  style: TextStyle(
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

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onChanged == null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      child: Container(
        padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
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
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(
                  alpha: disabled ? 0.05 : 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: disabled ? profileDisabled : AppColors.accent,
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
                      color: disabled ? profileDisabled : AppColors.textPrimary,
                      fontSize: profileScaled(context, 16, min: 14, max: 17),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled ? profileDisabled : profileTextMuted,
                      fontSize: profileScaled(context, 13, min: 12, max: 13),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: profileScaled(context, 12, min: 8, max: 12)),
            Switch.adaptive(
              value: value,
              onChanged: disabled ? null : onChanged,
              activeThumbColor: AppColors.accent,
              activeTrackColor: AppColors.accent.withValues(alpha: 0.38),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}
