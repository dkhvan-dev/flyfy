import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/android_back_swipe_scope.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import 'edit_profile_screen.dart';
import 'profile_style.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final FileApi _fileApi = FileApi();

  Future<String?>? _avatarFuture;
  String _avatarKey = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<SessionProvider>().profile;
    final avatarFileId = (profile?.avatarFileId ?? '').trim();
    if (_avatarFuture == null || _avatarKey != avatarFileId) {
      _avatarKey = avatarFileId;
      _avatarFuture = _resolveAvatarUrl(avatarFileId);
    }
  }

  Future<String?> _resolveAvatarUrl(String avatarFileId) async {
    if (avatarFileId.isEmpty) {
      return null;
    }
    return _fileApi.publicContentUrl(avatarFileId);
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AndroidBackSwipeScope(child: EditProfileScreen()),
      ),
    );

    if (updated == true && mounted) {
      _avatarFuture = null;
      _avatarKey = '';
      await context.read<SessionProvider>().reloadProfile();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.logoutDialogTitle),
          content: Text(l10n.logoutDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.logoutConfirmButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await authProvider.logout();
    await sessionProvider.clearSession();
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<SessionProvider>().profile;

    if (profile == null) {
      return Scaffold(
        body: ProfileResponsiveScope(
          child: ProfileGlassBackground(
            child: SafeArea(
              child: Center(
                child: Text(
                  l10n.profileNotAvailable,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ),
      );
    }

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
                _SubpageTopBar(title: l10n.profileSettingsPageTitle),
                SizedBox(height: profileScaled(context, 26, min: 18, max: 30)),
                FutureBuilder<String?>(
                  future: _avatarFuture,
                  builder: (context, snapshot) {
                    return _ProfileSettingsHero(
                      profile: profile,
                      avatarUrl: snapshot.data,
                      onEdit: _openEditProfile,
                    );
                  },
                ),
                SizedBox(height: profileScaled(context, 30, min: 24, max: 32)),
                ProfileSectionHeading(title: l10n.profileAccountSectionTitle),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _SettingsActionTile(
                  icon: Icons.edit_outlined,
                  title: l10n.editProfileButton,
                  subtitle: l10n.profileSettingsEditSubtitle,
                  onTap: _openEditProfile,
                ),
                _SettingsActionTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.profileNotificationsRowTitle,
                  subtitle: l10n.profileNotificationsRowSubtitle,
                  onTap: () => context.push('/profile/notifications'),
                ),
                _SettingsActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.profileSecurityRowTitle,
                  subtitle: l10n.profileSecurityRowSubtitle,
                  onTap: () => context.push('/profile/security'),
                ),
                SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
                ProfileSectionHeading(title: l10n.profileOverviewSectionTitle),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _ProfileOverviewCard(profile: profile),
                SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
                ProfileSectionHeading(title: l10n.profileMoreSectionTitle),
                SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
                _SettingsActionTile(
                  icon: Icons.explore_outlined,
                  title: l10n.profileGuideWorkspaceTitle,
                  subtitle: l10n.profileGuideWorkspaceSubtitle,
                  disabled: true,
                ),
                _SettingsActionTile(
                  icon: Icons.help_outline_rounded,
                  title: l10n.profileSupportTitle,
                  subtitle: l10n.profileSupportSubtitle,
                  disabled: true,
                ),
                SizedBox(height: profileScaled(context, 26, min: 20, max: 30)),
                FilledButton.tonal(
                  onPressed: _confirmLogout,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: Size(
                      double.infinity,
                      profileScaled(context, 54, min: 48, max: 56),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        profileScaled(context, 20, min: 18, max: 22),
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.logoutButton,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: profileScaled(context, 15, min: 14, max: 16),
                      fontWeight: FontWeight.w800,
                    ),
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

class _SubpageTopBar extends StatelessWidget {
  const _SubpageTopBar({required this.title});

  final String title;

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
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: profileScaled(context, 18, min: 16, max: 20),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        SizedBox(width: profileScaled(context, 38, min: 34, max: 40)),
      ],
    );
  }
}

class _ProfileSettingsHero extends StatelessWidget {
  const _ProfileSettingsHero({
    required this.profile,
    required this.avatarUrl,
    required this.onEdit,
  });

  final UserProfileVm profile;
  final String? avatarUrl;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(profileScaled(context, 22, min: 18, max: 24)),
      decoration: profileCardDecoration(
        context,
        highlighted: true,
        radius: profileScaled(context, 28, min: 22, max: 30),
      ),
      child: Column(
        children: [
          _SettingsAvatar(
            initials: profile.initials,
            avatarUrl: avatarUrl,
            isGuide: profile.isGuide,
          ),
          SizedBox(height: profileScaled(context, 18, min: 14, max: 20)),
          Text(
            profile.preferredName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: profileScaled(context, 26, min: 22, max: 28),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: profileScaled(context, 10, min: 8, max: 10),
            runSpacing: profileScaled(context, 10, min: 8, max: 10),
            children: [
              _MiniPill(
                text: profile.isGuide
                    ? l10n.profileVerifiedExplorer
                    : l10n.profileTitle,
                highlighted: profile.isGuide,
              ),
            ],
          ),
          SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        ],
      ),
    );
  }
}

class _SettingsAvatar extends StatelessWidget {
  const _SettingsAvatar({
    required this.initials,
    required this.avatarUrl,
    required this.isGuide,
  });

  final String initials;
  final String? avatarUrl;
  final bool isGuide;

  @override
  Widget build(BuildContext context) {
    final size = profileScaled(context, 112, min: 96, max: 120);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(profileScaled(context, 4, min: 3, max: 5)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
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
          child: avatarUrl == null
              ? Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: const Color(0xFF516572),
                      fontSize: profileScaled(context, 34, min: 28, max: 36),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: const Color(0xFF516572),
                        fontSize: profileScaled(context, 34, min: 28, max: 36),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.profile});

  final UserProfileVm profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (l10n.profileLocale, (profile.locale).toUpperCase()),
      (l10n.profileTimezone, profile.timezone),
      (
        l10n.profileCountry,
        (profile.countryCode ?? '').trim().isEmpty
            ? l10n.notSpecified
            : profile.countryCode!.trim(),
      ),
      (
        l10n.profileCurrency,
        (profile.currency ?? '').trim().isEmpty
            ? l10n.notSpecified
            : profile.currency!.trim(),
      ),
    ];

    return Container(
      decoration: profileCardDecoration(
        context,
        radius: profileScaled(context, 24, min: 20, max: 26),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 18, min: 14, max: 20),
              vertical: profileScaled(context, 16, min: 14, max: 18),
            ),
            decoration: BoxDecoration(
              border: index == items.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.$1,
                    style: TextStyle(
                      color: profileTextSoft,
                      fontSize: profileScaled(context, 13, min: 12, max: 13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: profileScaled(context, 14, min: 10, max: 14)),
                Flexible(
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: profileScaled(context, 14, min: 13, max: 15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = disabled || onTap == null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      child: InkWell(
        onTap: effectiveDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(
          profileScaled(context, 22, min: 18, max: 22),
        ),
        child: Ink(
          padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
          decoration: profileCardDecoration(
            context,
            disabled: effectiveDisabled,
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
                    alpha: effectiveDisabled ? 0.05 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: effectiveDisabled ? profileDisabled : AppColors.accent,
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
                        color: effectiveDisabled
                            ? profileDisabled
                            : AppColors.textPrimary,
                        fontSize: profileScaled(context, 16, min: 14, max: 17),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: effectiveDisabled
                            ? profileDisabled
                            : profileTextMuted,
                        fontSize: profileScaled(context, 13, min: 12, max: 13),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
              Icon(
                effectiveDisabled
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                color: effectiveDisabled ? profileDisabled : profileTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 12, min: 10, max: 14),
        vertical: profileScaled(context, 7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlighted ? AppColors.accent : profileTextSoft,
          fontSize: profileScaled(context, 11, min: 10, max: 12),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
