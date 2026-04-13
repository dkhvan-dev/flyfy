import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/app_lock_service.dart';
import '../../core/auth/biometric_auth_service.dart';
import '../../core/ui/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'profile_style.dart';

class ProfileSecurityScreen extends StatefulWidget {
  const ProfileSecurityScreen({super.key});

  @override
  State<ProfileSecurityScreen> createState() => _ProfileSecurityScreenState();
}

class _ProfileSecurityScreenState extends State<ProfileSecurityScreen> {
  final AppLockService _appLockService = AppLockService();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  bool _isLoading = true;
  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _hasStoredSession = false;
  bool _isTogglingBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final results = await Future.wait<bool>([
      _appLockService.hasPin(),
      _appLockService.isBiometricEnabled(),
      _biometricAuthService.isAvailable(),
      _appLockService.hasStoredSession(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _hasPin = results[0];
      _biometricEnabled = results[1];
      _biometricAvailable = results[2];
      _hasStoredSession = results[3];
      _isLoading = false;
    });
  }

  Future<void> _setBiometricEnabled(bool value) async {
    if (_isTogglingBiometric || !_biometricAvailable || !_hasPin) {
      return;
    }

    setState(() {
      _isTogglingBiometric = true;
      _biometricEnabled = value;
    });

    try {
      await _appLockService.setBiometricEnabled(value);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricEnabled = !value;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingBiometric = false;
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
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
                      const _SecurityTopBar(),
                      SizedBox(
                        height: profileScaled(context, 24, min: 18, max: 28),
                      ),
                      _SecurityHero(
                        title: l10n.profileSecurityHeroTitle,
                        subtitle: l10n.profileSecurityHeroSubtitle,
                      ),
                      SizedBox(
                        height: profileScaled(context, 28, min: 24, max: 32),
                      ),
                      ProfileSectionHeading(
                        title: l10n.profileSecurityLocalAccessSection,
                      ),
                      SizedBox(
                        height: profileScaled(context, 16, min: 12, max: 18),
                      ),
                      _SecurityInfoTile(
                        icon: Icons.pin_outlined,
                        title: l10n.profileSecurityPinTitle,
                        subtitle: _hasPin
                            ? l10n.profileSecurityPinEnabledSubtitle
                            : l10n.profileSecurityPinMissingSubtitle,
                        statusLabel: _hasPin
                            ? l10n.profileStatusEnabled
                            : l10n.profileStatusDisabled,
                        highlighted: _hasPin,
                      ),
                      _SecuritySwitchTile(
                        icon: Icons.fingerprint_rounded,
                        title: l10n.profileSecurityBiometricTitle,
                        subtitle: !_hasPin
                            ? l10n.profileSecurityBiometricNeedsPin
                            : _biometricAvailable
                            ? l10n.profileSecurityBiometricSubtitle
                            : l10n.profileSecurityBiometricUnavailable,
                        value: _biometricEnabled,
                        enabled:
                            _biometricAvailable &&
                            _hasPin &&
                            !_isTogglingBiometric,
                        onChanged: _setBiometricEnabled,
                      ),
                      SizedBox(
                        height: profileScaled(context, 28, min: 24, max: 32),
                      ),
                      ProfileSectionHeading(
                        title: l10n.profileSecurityAccountSection,
                      ),
                      SizedBox(
                        height: profileScaled(context, 16, min: 12, max: 18),
                      ),
                      _SecurityInfoTile(
                        icon: Icons.shield_outlined,
                        title: l10n.profileSecurityProtectedSessionTitle,
                        subtitle: _hasStoredSession
                            ? l10n.profileSecurityProtectedSessionSubtitle
                            : l10n.profileSecurityNoStoredSessionSubtitle,
                        statusLabel: _hasStoredSession
                            ? l10n.profileStatusEnabled
                            : l10n.profileStatusDisabled,
                        highlighted: _hasStoredSession,
                      ),
                      _SecurityInfoTile(
                        icon: Icons.verified_user_outlined,
                        title: l10n.profileSecurityTwoFactorTitle,
                        subtitle: l10n.profileSecurityTwoFactorSubtitle,
                        statusLabel: l10n.profileDisabledSoon,
                        disabled: true,
                      ),
                      SizedBox(
                        height: profileScaled(context, 28, min: 24, max: 32),
                      ),
                      ProfileSectionHeading(
                        title: l10n.profileSecurityDataSection,
                      ),
                      SizedBox(
                        height: profileScaled(context, 16, min: 12, max: 18),
                      ),
                      _SecurityInfoTile(
                        icon: Icons.download_outlined,
                        title: l10n.profileSecurityDataExportTitle,
                        subtitle: l10n.profileSecurityDataExportSubtitle,
                        statusLabel: l10n.profileDisabledSoon,
                        disabled: true,
                      ),
                      _SecurityInfoTile(
                        icon: Icons.delete_outline_rounded,
                        title: l10n.profileSecurityDeleteTitle,
                        subtitle: l10n.profileSecurityDeleteSubtitle,
                        statusLabel: l10n.profileDisabledSoon,
                        disabled: true,
                        danger: true,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecurityTopBar extends StatelessWidget {
  const _SecurityTopBar();

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
              AppLocalizations.of(context)!.profileSecurityPageTitle,
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

class _SecurityHero extends StatelessWidget {
  const _SecurityHero({required this.title, required this.subtitle});

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
              Icons.security_rounded,
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

class _SecurityInfoTile extends StatelessWidget {
  const _SecurityInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.disabled = false,
    this.highlighted = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final bool disabled;
  final bool highlighted;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accentColor = danger
        ? const Color(0xFFF2A099)
        : highlighted
        ? AppColors.accent
        : profileTextSoft;

    return Padding(
      padding: EdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      child: Container(
        padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
        decoration: profileCardDecoration(
          context,
          disabled: disabled,
          highlighted: highlighted && !disabled,
          radius: profileScaled(context, 22, min: 18, max: 24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: profileScaled(context, 46, min: 40, max: 48),
              height: profileScaled(context, 46, min: 40, max: 48),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: disabled ? 0.06 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor),
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
            SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
            _StatusTag(
              label: statusLabel,
              color: accentColor,
              disabled: disabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecuritySwitchTile extends StatelessWidget {
  const _SecuritySwitchTile({
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
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      child: Container(
        padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
        decoration: profileCardDecoration(
          context,
          disabled: !enabled,
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
                  alpha: enabled ? 0.14 : 0.06,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: enabled ? AppColors.accent : profileDisabled,
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
                      color: enabled ? AppColors.textPrimary : profileDisabled,
                      fontSize: profileScaled(context, 16, min: 14, max: 17),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: enabled ? profileTextMuted : profileDisabled,
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
              onChanged: enabled ? onChanged : null,
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

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.color,
    required this.disabled,
  });

  final String label;
  final Color color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 12, min: 10, max: 14),
        vertical: profileScaled(context, 7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: disabled ? 0.04 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: disabled ? 0.05 : 0.18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: disabled ? profileDisabled : color,
          fontSize: profileScaled(context, 11, min: 10, max: 12),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
