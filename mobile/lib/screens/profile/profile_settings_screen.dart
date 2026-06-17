import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/android_back_swipe_scope.dart';
import '../../core/network/reference_api.dart';
import '../../core/reference/country_filter_utils.dart';
import '../../core/reference/currency_filter_utils.dart';
import '../../core/reference/timezone_filter_utils.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_language_sheet.dart';
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
      profile?.timezone ?? '',
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
    final timezoneId = normalizeReferenceTimezoneId(profile?.timezone);
    final currencyCode = normalizeReferenceCurrencyCode(profile?.currency);

    final labels = await Future.wait<String?>([
      _resolveCountryLabel(countryCode, lang),
      _resolveTimezoneLabel(timezoneId, lang),
      _resolveCurrencyLabel(currencyCode, lang),
    ]);

    return _ProfileReferenceLabels(
      country: labels[0],
      timezone: labels[1],
      currency: labels[2],
    );
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

  Future<String?> _resolveTimezoneLabel(String? timezoneId, String lang) async {
    if (timezoneId == null) return null;

    try {
      final timezones = withDefaultReferenceTimezone(
        await _referenceApi.listTimezones(lang: lang),
        timezoneId,
        lang: lang,
      );
      for (final timezone in timezones) {
        if (normalizeReferenceTimezoneId(timezone.id) == timezoneId) {
          return referenceTimezoneLabel(timezone, lang: lang);
        }
      }
    } catch (_) {
      // Fallback below keeps the profile usable on poor networks.
    }

    return referenceTimezoneLabel(
      ReferenceTimezone(
        id: timezoneId,
        name: localizedReferenceTimezoneFallbackName(timezoneId, lang),
      ),
      lang: lang,
    );
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
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshProfileSettings,
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
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
                  ProfileSectionHeading(title: l10n.profileAccountSectionTitle),
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

class _ProfileReferenceLabels {
  const _ProfileReferenceLabels({this.country, this.timezone, this.currency});

  final String? country;
  final String? timezone;
  final String? currency;
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.profile, this.labels});

  final UserProfileVm profile;
  final _ProfileReferenceLabels? labels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        l10n.profileTimezone,
        _resolvedValue(labels?.timezone, profile.timezone, l10n.notSpecified),
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
    final effectiveDisabled = onTap == null;
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
