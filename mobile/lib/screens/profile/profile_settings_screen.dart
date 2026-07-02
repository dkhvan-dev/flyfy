import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/android_back_swipe_scope.dart';
import '../../core/network/reference_api.dart';
import '../../core/reference/country_filter_utils.dart';
import '../../core/reference/currency_filter_utils.dart';
import '../../core/ui/app_language_sheet.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_mode_provider.dart';
import 'edit_profile_screen.dart';
import 'profile_style.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ReferenceApi _referenceApi = ReferenceApi();

  Future<_ProfileReferenceLabels>? _referenceLabelsFuture;
  String _referenceLabelsKey = '';

  Future<_ProfileReferenceLabels> _referenceLabelsFutureFor(
    UserProfileVm? profile,
    String lang,
  ) {
    final nextKey = [
      lang,
      profile?.countryCode ?? '',
      profile?.currency ?? '',
    ].join('|');

    if (_referenceLabelsFuture == null || _referenceLabelsKey != nextKey) {
      _referenceLabelsKey = nextKey;
      _referenceLabelsFuture = _resolveReferenceLabels(profile, lang);
    }

    return _referenceLabelsFuture!;
  }

  Future<void> _refreshProfileSettings() async {
    setState(() {
      _referenceLabelsFuture = null;
      _referenceLabelsKey = '';
    });

    await context.read<SessionProvider>().reloadProfile();
  }

  Future<_ProfileReferenceLabels> _resolveReferenceLabels(
    UserProfileVm? profile,
    String lang,
  ) async {
    final countryCode = normalizeReferenceCountryCode(profile?.countryCode);
    final currencyCode = normalizeReferenceCurrencyCode(profile?.currency);

    final labels = await Future.wait<String?>([
      _resolveCountryLabel(countryCode, lang),
      _resolveCurrencyLabel(currencyCode, lang),
    ]);

    return _ProfileReferenceLabels(country: labels[0], currency: labels[1]);
  }

  Future<String?> _resolveCountryLabel(String? countryCode, String lang) async {
    if (countryCode == null) return null;

    try {
      final country = await _referenceApi.getCountry(countryCode, lang: lang);
      final name = country?.name.trim() ?? '';
      return name.isEmpty ? countryCode : name;
    } catch (_) {
      // Keep settings readable on poor networks.
      return countryCode;
    }
  }

  Future<String?> _resolveCurrencyLabel(
    String? currencyCode,
    String lang,
  ) async {
    if (currencyCode == null) return null;

    try {
      final currencies = withDefaultReferenceCurrency(
        await _referenceApi.listCurrencies(lang: lang),
        currencyCode,
      );
      for (final currency in currencies) {
        if (normalizeReferenceCurrencyCode(currency.code) == currencyCode) {
          return _currencyCodeWithSymbol(currency);
        }
      }
    } catch (_) {
      // Keep settings readable on poor networks.
    }

    return currencyCode;
  }

  String _currencyCodeWithSymbol(ReferenceCurrency currency) {
    final code =
        normalizeReferenceCurrencyCode(currency.code) ??
        currency.code.trim().toUpperCase();
    final symbol = currency.symbol.trim();
    if (code.isEmpty) return symbol;
    if (symbol.isEmpty || symbol == code) return code;
    return '$code ($symbol)';
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AndroidBackSwipeScope(child: EditProfileScreen()),
      ),
    );

    if (updated == true && mounted) {
      _referenceLabelsFuture = null;
      _referenceLabelsKey = '';
      await context.read<SessionProvider>().reloadProfile();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _openAppLanguageSettings() {
    return showAppLanguageSheet(context);
  }

  Future<void> _openAppThemeSettings() {
    final themeModeProvider = context.read<ThemeModeProvider>();
    final l10n = AppLocalizations.of(context)!;

    return showAppModalBottomSheet<void>(
      context: context,
      title: l10n.appThemeTitle,
      subtitle: l10n.appThemeSubtitle,
      icon: Icons.contrast_rounded,
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.72,
      builder: (sheetContext) {
        final colors = AppDesignSystem.colorsFor(sheetContext);
        return RadioGroup<AppThemeModePreference>(
          groupValue: themeModeProvider.selectedMode,
          onChanged: (value) async {
            if (value == null) return;

            await themeModeProvider.setThemeMode(value);
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in AppThemeModePreference.values)
                RadioListTile<AppThemeModePreference>(
                  value: mode,
                  activeColor: colors.primary,
                  contentPadding: AppEdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: Icon(_themeModeIcon(mode), color: colors.primary),
                  title: Text(
                    _themeModeLabel(l10n, mode),
                    style: AppTextStyle(
                      color: colors.textPrimary,
                      fontSize: profileScaled(context, 15, min: 14, max: 16),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    _themeModeDescription(l10n, mode),
                    style: AppTextStyle(
                      color: colors.textMuted,
                      fontSize: profileScaled(context, 13, min: 12, max: 13),
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _themeModeLabel(AppLocalizations l10n, AppThemeModePreference mode) {
    return switch (mode) {
      AppThemeModePreference.system => l10n.appThemeSystem,
      AppThemeModePreference.light => l10n.appThemeLight,
      AppThemeModePreference.dark => l10n.appThemeDark,
    };
  }

  String _themeModeDescription(
    AppLocalizations l10n,
    AppThemeModePreference mode,
  ) {
    return switch (mode) {
      AppThemeModePreference.system => l10n.appThemeSystemDescription,
      AppThemeModePreference.light => l10n.appThemeLightDescription,
      AppThemeModePreference.dark => l10n.appThemeDarkDescription,
    };
  }

  IconData _themeModeIcon(AppThemeModePreference mode) {
    return switch (mode) {
      AppThemeModePreference.system => Icons.brightness_auto_rounded,
      AppThemeModePreference.light => Icons.light_mode_rounded,
      AppThemeModePreference.dark => Icons.dark_mode_rounded,
    };
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();
    final confirmed = await showAppModalDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _LogoutConfirmDialog(
          title: l10n.logoutDialogTitle,
          message: l10n.logoutDialogMessage,
          cancelLabel: l10n.cancelButton,
          confirmLabel: l10n.logoutConfirmButton,
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
    final colors = AppDesignSystem.colorsFor(context);
    final profile = context.watch<SessionProvider>().profile;

    if (profile == null) {
      return Theme(
        data: AppDesignSystem.themeFor(context),
        child: Scaffold(
          backgroundColor: colors.background,
          body: ProfileResponsiveScope(
            child: DecoratedBox(
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors.screenGradientColors,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Text(
                    l10n.profileNotAvailable,
                    style: AppTextStyle(color: colors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final padding = profileScaled(context, 20, min: 14, max: 20);
    final lang = Localizations.localeOf(context).languageCode;
    final selectedThemeMode = context.watch<ThemeModeProvider>().selectedMode;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: ProfileResponsiveScope(
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.screenGradientColors,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshProfileSettings,
                color: colors.primary,
                backgroundColor: colors.surface,
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
                    _SubpageTopBar(title: l10n.profileSettingsPageTitle),
                    SizedBox(
                      height: profileScaled(context, 26, min: 18, max: 30),
                    ),
                    ProfileSectionHeading(
                      title: l10n.profileOverviewSectionTitle,
                    ),
                    SizedBox(
                      height: profileScaled(context, 16, min: 12, max: 18),
                    ),
                    FutureBuilder<_ProfileReferenceLabels>(
                      future: _referenceLabelsFutureFor(profile, lang),
                      builder: (context, snapshot) {
                        return _ProfileOverviewCard(
                          profile: profile,
                          labels: snapshot.data,
                        );
                      },
                    ),
                    SizedBox(
                      height: profileScaled(context, 28, min: 24, max: 32),
                    ),
                    ProfileSectionHeading(
                      title: l10n.profileAccountSectionTitle,
                    ),
                    SizedBox(
                      height: profileScaled(context, 16, min: 12, max: 18),
                    ),
                    _SettingsActionTile(
                      icon: Icons.edit_outlined,
                      title: l10n.editProfileButton,
                      subtitle: l10n.profileSettingsEditSubtitle,
                      onTap: _openEditProfile,
                    ),
                    _SettingsActionTile(
                      icon: Icons.language_rounded,
                      title: l10n.appLanguageTitle,
                      subtitle: l10n.profileLocale,
                      onTap: _openAppLanguageSettings,
                    ),
                    _SettingsActionTile(
                      icon: Icons.contrast_rounded,
                      title: l10n.appThemeTitle,
                      subtitle: _themeModeLabel(l10n, selectedThemeMode),
                      onTap: _openAppThemeSettings,
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
                    SizedBox(
                      height: profileScaled(context, 26, min: 20, max: 30),
                    ),
                    FilledButton.tonal(
                      onPressed: _confirmLogout,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.danger,
                        foregroundColor: colors.white,
                        minimumSize: Size(
                          double.infinity,
                          profileScaled(context, 54, min: 48, max: 56),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.circular(
                            profileScaled(context, 20, min: 18, max: 22),
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.logoutButton,
                        style: AppTextStyle(
                          color: colors.white,
                          fontSize: profileScaled(
                            context,
                            15,
                            min: 14,
                            max: 16,
                          ),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    final colors = AppDesignSystem.colorsFor(context);
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
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textPrimary,
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

class _ProfileReferenceLabels {
  const _ProfileReferenceLabels({this.country, this.currency});

  final String? country;
  final String? currency;
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.84;
    final radius = AppBorderRadius.circular(
      profileScaled(context, 28, min: 24, max: 30),
    );

    return Dialog(
      insetPadding: AppEdgeInsets.symmetric(
        horizontal: profileScaled(context, 18, min: 14, max: 24),
        vertical: profileScaled(context, 24, min: 18, max: 28),
      ),
      backgroundColor: colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 390,
            maxHeight: maxDialogHeight,
          ),
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors.screenGradientColors,
              ),
              border: Border.all(color: colors.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: colors.black.withValues(alpha: 0.32),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: SingleChildScrollView(
                padding: AppEdgeInsets.all(
                  profileScaled(context, 22, min: 18, max: 24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: profileScaled(context, 58, min: 52, max: 62),
                        height: profileScaled(context, 58, min: 52, max: 62),
                        decoration: AppBoxDecoration(
                          borderRadius: AppBorderRadius.circular(
                            profileScaled(context, 20, min: 18, max: 22),
                          ),
                          color: colors.primary.withValues(alpha: 0.14),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 18, min: 14, max: 20),
                    ),
                    Text(
                      title,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: profileScaled(context, 24, min: 21, max: 26),
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 10, min: 8, max: 12),
                    ),
                    Text(
                      message,
                      style: AppTextStyle(
                        color: colors.textSecondary,
                        fontSize: profileScaled(context, 15, min: 14, max: 16),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 22, min: 18, max: 24),
                    ),
                    Wrap(
                      spacing: profileScaled(context, 10, min: 8, max: 12),
                      runSpacing: profileScaled(context, 10, min: 8, max: 12),
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            side: BorderSide(color: colors.border),
                            minimumSize: const Size(132, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            cancelLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.textPrimary,
                            minimumSize: const Size(132, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            confirmLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
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
  const _ProfileOverviewCard({required this.profile, this.labels});

  final UserProfileVm profile;
  final _ProfileReferenceLabels? labels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final items = [
      (
        l10n.profileFullName,
        _resolvedValue(null, profile.fullName, l10n.notSpecified),
      ),
      (
        l10n.profilePhone,
        _resolvedValue(null, profile.primaryPhoneDisplay, l10n.notSpecified),
      ),
      (
        l10n.profileCountry,
        _resolvedValue(labels?.country, profile.countryCode, l10n.notSpecified),
      ),
      (
        l10n.profileCurrency,
        _resolvedValue(labels?.currency, profile.currency, l10n.notSpecified),
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
            padding: AppEdgeInsets.symmetric(
              horizontal: profileScaled(context, 18, min: 14, max: 20),
              vertical: profileScaled(context, 16, min: 14, max: 18),
            ),
            decoration: AppBoxDecoration(
              border: index == items.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: colors.borderSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.$1,
                    style: AppTextStyle(
                      color: colors.textSecondary,
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
                    style: AppTextStyle(
                      color: colors.textPrimary,
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

  String _resolvedValue(
    String? localized,
    String? fallback,
    String emptyLabel,
  ) {
    final localizedValue = (localized ?? '').trim();
    if (localizedValue.isNotEmpty) return localizedValue;

    final fallbackValue = (fallback ?? '').trim();
    return fallbackValue.isEmpty ? emptyLabel : fallbackValue;
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final effectiveDisabled = onTap == null;
    return Padding(
      padding: AppEdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      child: InkWell(
        onTap: effectiveDisabled ? null : onTap,
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 22, min: 18, max: 22),
        ),
        child: Ink(
          padding: AppEdgeInsets.all(
            profileScaled(context, 18, min: 14, max: 20),
          ),
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
                decoration: AppBoxDecoration(
                  color: colors.primary.withValues(
                    alpha: effectiveDisabled ? 0.05 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: effectiveDisabled
                      ? colors.textDisabled
                      : colors.primary,
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
                        color: effectiveDisabled
                            ? colors.textDisabled
                            : colors.textPrimary,
                        fontSize: profileScaled(context, 16, min: 14, max: 17),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                    Text(
                      subtitle,
                      style: AppTextStyle(
                        color: effectiveDisabled
                            ? colors.textDisabled
                            : colors.textMuted,
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
                color: effectiveDisabled
                    ? colors.textDisabled
                    : colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
