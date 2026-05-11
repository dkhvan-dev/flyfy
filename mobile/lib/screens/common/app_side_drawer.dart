import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';

enum AppDrawerActiveItem { none, myActivities, myStories }

const Map<String, Map<String, String>> _localizedCountryNames = {
  'KZ': {'en': 'Kazakhstan', 'ru': 'Казахстан', 'kk': 'Қазақстан'},
};

const Map<String, Map<String, String>> _localizedCityNames = {
  'Almaty': {'en': 'Almaty', 'ru': 'Алматы', 'kk': 'Алматы'},
  'Astana': {'en': 'Astana', 'ru': 'Астана', 'kk': 'Астана'},
};

String resolveDrawerLocation(UserProfileVm? profile, Locale locale) {
  final languageCode = locale.languageCode;
  final timezone = (profile?.timezone ?? '').trim();
  final city = _resolveLocalizedCity(timezone, languageCode);
  final country = _resolveLocalizedCountry(
    (profile?.countryCode ?? '').trim(),
    languageCode,
  );

  if (country.isNotEmpty && city.isNotEmpty) {
    return '$country, $city';
  }
  if (city.isNotEmpty) return city;
  if (country.isNotEmpty) return country;

  return _localizedCityNames['Almaty']?[languageCode] ?? 'Almaty';
}

String resolveDrawerLanguageLabel(String code) {
  return code.toUpperCase();
}

Future<void> showAppLanguageSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final localeProvider = context.read<LocaleProvider>();
  final currentCode = localeProvider.locale.languageCode;
  final selectedCode = await showModalBottomSheet<String>(
    context: context,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    isScrollControlled: true,
    builder: (sheetContext) {
      final screenWidth = MediaQuery.sizeOf(sheetContext).width;
      final isCompact = screenWidth < 375;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final horizontalPadding = isCompact ? 22.0 : 26.0;
      final sheetRadius = isCompact ? 30.0 : 34.0;
      final iconWrapSize = isCompact ? 136.0 : 148.0;
      final glowSize = isCompact ? 156.0 : 170.0;
      final iconSize = isCompact ? 56.0 : 60.0;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF211207), Color(0xFF170D06)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(sheetRadius),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 40,
                      offset: const Offset(0, -12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.02),
                                Colors.transparent,
                              ],
                              stops: const [0, 0.16],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -24,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, 0.7),
                              radius: 0.95,
                              colors: [
                                AppColors.accent.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isCompact ? 24 : 28,
                        horizontalPadding,
                        isCompact ? 24 : 30,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 76,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 26 : 34),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.accent.withValues(alpha: 0.26),
                                      AppColors.accent.withValues(alpha: 0.12),
                                      AppColors.accent.withValues(alpha: 0.04),
                                      Colors.transparent,
                                    ],
                                    stops: const [0, 0.3, 0.52, 0.78],
                                  ),
                                ),
                              ),
                              Container(
                                width: iconWrapSize,
                                height: iconWrapSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: const Alignment(0, -0.25),
                                    colors: [
                                      AppColors.accent.withValues(alpha: 0.05),
                                      AppColors.accent.withValues(alpha: 0.01),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.36,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 28,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.language_rounded,
                                  size: iconSize,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 22 : 26),
                          Text(
                            l10n.appLanguageTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: isCompact ? 14 : 18,
                              height: 0.98,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.1,
                            ),
                          ),
                          SizedBox(height: isCompact ? 28 : 34),
                          for (final option in _languageOptions) ...[
                            _LanguageOptionTile(
                              label: option.label,
                              code: option.code.toUpperCase(),
                              isSelected: currentCode == option.code,
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(option.code),
                            ),
                            if (option != _languageOptions.last)
                              SizedBox(height: isCompact ? 14 : 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  if (selectedCode == null || !context.mounted) return;
  await localeProvider.setLocale(selectedCode);
}

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({
    super.key,
    required this.l10n,
    required this.isLoggedIn,
    required this.showGuideBadge,
    required this.profile,
    required this.location,
    required this.languageLabel,
    required this.activeItem,
    required this.onProfileTap,
    required this.onLanguageTap,
    required this.onHomeTap,
    required this.onMyActivitiesTap,
    required this.onMyStoriesTap,
    required this.onActivitiesTap,
    required this.onLoginTap,
    required this.onLogoutTap,
  });

  final AppLocalizations l10n;
  final bool isLoggedIn;
  final bool showGuideBadge;
  final UserProfileVm? profile;
  final String location;
  final String languageLabel;
  final AppDrawerActiveItem activeItem;
  final VoidCallback onProfileTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onMyActivitiesTap;
  final VoidCallback onMyStoriesTap;
  final VoidCallback onActivitiesTap;
  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final layout = _AppDrawerLayout.of(context);
    final profileTitle =
        isLoggedIn ? profile?.preferredName ?? 'FlyFy' : 'FlyFy';
    final profileSubtitle = isLoggedIn ? location : l10n.homeSubtitle;
    final avatarText = profile?.initials ?? 'F';
    final avatarUrl = resolvePublicFileContentUrl(
      (profile?.avatarFileId ?? '').trim(),
    );
    return Drawer(
      width: layout.drawerWidth,
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(layout.panelRadius),
          bottomRight: Radius.circular(layout.panelRadius),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B120B), Color(0xFF0F0906)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 40,
                offset: const Offset(10, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.13),
                          Colors.transparent,
                          AppColors.accent.withValues(alpha: 0.05),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -80,
                left: -70,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        layout.topPadding,
                        layout.horizontalPadding,
                        layout.sectionGap,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isLoggedIn ? onProfileTap : onLoginTap,
                                borderRadius: BorderRadius.circular(
                                  layout.cardRadius,
                                ),
                                child: Ink(
                                  padding: EdgeInsets.all(layout.cardPadding),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      layout.cardRadius,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.05),
                                        AppColors.accent.withValues(
                                          alpha: 0.10,
                                        ),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.24,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: layout.avatarSize,
                                            height: layout.avatarSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0xFFFDF9F4),
                                                  Color(0xFFF2E7DA),
                                                ],
                                              ),
                                              border: Border.all(
                                                color: AppColors.accent,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 22,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: ClipOval(
                                                child: SizedBox.expand(
                                                  child: avatarUrl == null
                                                      ? Center(
                                                          child: Text(
                                                            avatarText,
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .background,
                                                              fontSize: layout
                                                                  .avatarTextSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        )
                                                      : Image.network(
                                                          avatarUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (_, __, ___) =>
                                                                  Center(
                                                            child: Text(
                                                              avatarText,
                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .background,
                                                                fontSize: layout
                                                                    .avatarTextSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (showGuideBadge)
                                            Positioned(
                                              right: -2,
                                              bottom: 8,
                                              child: Container(
                                                width: layout.avatarBadgeSize,
                                                height: layout.avatarBadgeSize,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                      const LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Color(0xFFFFB347),
                                                      Color(0xFFF98C06),
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2B170C,
                                                    ),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.verified_rounded,
                                                  size: layout
                                                      .avatarBadgeIconSize,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(width: layout.profileGap),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.18),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                isLoggedIn
                                                    ? l10n.profileTitle
                                                    : l10n.loginButton,
                                                style: TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize:
                                                      layout.metaLabelSize,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: layout.profileTextGap,
                                            ),
                                            Text(
                                              profileTitle,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize:
                                                    layout.profileTitleSize,
                                                height: 1.05,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(
                                              height: layout.profileTextGap,
                                            ),
                                            Text(
                                              profileSubtitle,
                                              maxLines: isLoggedIn ? 1 : 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.74,
                                                ),
                                                fontSize:
                                                    layout.profileSubtitleSize,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: layout.trailingGap),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.55,
                                        ),
                                        size: layout.trailingIconSize,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: layout.sectionGap),
                            _DrawerMenuItem(
                              layout: layout,
                              icon: Icons.language_rounded,
                              iconWidget: Center(
                                child: Text(
                                  languageLabel,
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: layout.iconBoxSize * 0.36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              label: l10n.appLanguageTitle,
                              labelFontSize: layout.menuLabelSize - 3,
                              usePreferencePalette: true,
                              onTap: onLanguageTap,
                            ),
                            SizedBox(height: layout.sectionGap),
                            _DrawerSectionTitle(
                              title: l10n.homeExploreServices,
                              layout: layout,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.myActivitiesTitle,
                              icon: Icons.event_note_rounded,
                              isActive: activeItem ==
                                  AppDrawerActiveItem.myActivities,
                              usePreferencePalette: true,
                              onTap: onMyActivitiesTap,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.myStoriesTitle,
                              icon: Icons.auto_stories_rounded,
                              isActive:
                                  activeItem == AppDrawerActiveItem.myStories,
                              usePreferencePalette: true,
                              onTap: onMyStoriesTap,
                            ),
                            SizedBox(height: layout.menuGap),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          layout.horizontalPadding,
                          0,
                          layout.horizontalPadding,
                          layout.bottomPadding,
                        ),
                        child: Column(
                          children: [
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.only(
                                top: layout.footerTopPadding,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.homeTitle,
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: layout.brandTitleSize,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n.homeSubtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.50,
                                            ),
                                            fontSize: layout.brandSubtitleSize,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: layout.footerGap),
                                  _DrawerFooterAction(
                                    layout: layout,
                                    icon: isLoggedIn
                                        ? Icons.logout_rounded
                                        : Icons.login_rounded,
                                    isAccent: !isLoggedIn,
                                    onTap:
                                        isLoggedIn ? onLogoutTap : onLoginTap,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _resolveLocalizedCountry(String countryCode, String languageCode) {
  if (countryCode.isEmpty) return '';

  final normalizedCode = countryCode.toUpperCase();
  return _localizedCountryNames[normalizedCode]?[languageCode] ??
      normalizedCode;
}

String _resolveLocalizedCity(String timezone, String languageCode) {
  if (timezone.isEmpty) return '';

  final timezoneParts = timezone.split('/');
  if (timezoneParts.length > 1 && timezoneParts.last.trim().isNotEmpty) {
    final cityKey = timezoneParts.last.trim().replaceAll('_', ' ');
    return _localizedCityNames[cityKey]?[languageCode] ?? cityKey;
  }

  return '';
}

class _AppDrawerLayout {
  const _AppDrawerLayout({
    required this.drawerWidth,
    required this.panelRadius,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.cardRadius,
    required this.cardPadding,
    required this.avatarSize,
    required this.avatarTextSize,
    required this.avatarBadgeSize,
    required this.avatarBadgeIconSize,
    required this.profileGap,
    required this.profileTextGap,
    required this.profileTitleSize,
    required this.profileSubtitleSize,
    required this.metaLabelSize,
    required this.trailingGap,
    required this.trailingIconSize,
    required this.sectionGap,
    required this.menuGap,
    required this.menuMinHeight,
    required this.iconBoxSize,
    required this.menuLabelSize,
    required this.footerTopPadding,
    required this.footerGap,
    required this.footerButtonSize,
    required this.brandTitleSize,
    required this.brandSubtitleSize,
    required this.sectionTitleSize,
  });

  final double drawerWidth;
  final double panelRadius;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double cardRadius;
  final double cardPadding;
  final double avatarSize;
  final double avatarTextSize;
  final double avatarBadgeSize;
  final double avatarBadgeIconSize;
  final double profileGap;
  final double profileTextGap;
  final double profileTitleSize;
  final double profileSubtitleSize;
  final double metaLabelSize;
  final double trailingGap;
  final double trailingIconSize;
  final double sectionGap;
  final double menuGap;
  final double menuMinHeight;
  final double iconBoxSize;
  final double menuLabelSize;
  final double footerTopPadding;
  final double footerGap;
  final double footerButtonSize;
  final double brandTitleSize;
  final double brandSubtitleSize;
  final double sectionTitleSize;

  static _AppDrawerLayout of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final isCompact = width < 375;
    final isShort = height < 740;

    return _AppDrawerLayout(
      drawerWidth: (width * 0.88).clamp(292.0, 388.0).toDouble(),
      panelRadius: width < 420 ? 28 : 32,
      horizontalPadding: isCompact ? 18 : 24,
      topPadding: isShort ? 10 : 14,
      bottomPadding: isShort ? 18 : 22,
      cardRadius: isCompact ? 22 : 26,
      cardPadding: isCompact ? 16 : 20,
      avatarSize: isCompact ? 84 : 100,
      avatarTextSize: isCompact ? 28 : 32,
      avatarBadgeSize: isCompact ? 28 : 32,
      avatarBadgeIconSize: isCompact ? 13 : 14,
      profileGap: isCompact ? 14 : 16,
      profileTextGap: isCompact ? 8 : 10,
      profileTitleSize: isCompact ? 22 : 24,
      profileSubtitleSize: isCompact ? 13 : 14,
      metaLabelSize: isCompact ? 11 : 12,
      trailingGap: isCompact ? 10 : 12,
      trailingIconSize: isCompact ? 20 : 22,
      sectionGap: isShort ? 24 : 30,
      menuGap: isCompact ? 12 : 14,
      menuMinHeight: isCompact ? 78 : 90,
      iconBoxSize: isCompact ? 48 : 54,
      menuLabelSize: isCompact ? 16 : 18,
      footerTopPadding: isCompact ? 16 : 18,
      footerGap: isCompact ? 12 : 16,
      footerButtonSize: isCompact ? 56 : 64,
      brandTitleSize: isCompact ? 22 : 24,
      brandSubtitleSize: isCompact ? 10.5 : 11,
      sectionTitleSize: isCompact ? 11 : 12,
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle({required this.title, required this.layout});

  final String title;
  final _AppDrawerLayout layout;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.86),
        fontSize: layout.sectionTitleSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.layout,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconWidget,
    this.labelFontSize,
    this.isActive = false,
    this.usePreferencePalette = false,
  });

  final _AppDrawerLayout layout;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? iconWidget;
  final double? labelFontSize;
  final bool isActive;
  final bool usePreferencePalette;

  @override
  Widget build(BuildContext context) {
    final matchesPreferencePalette = !isActive && usePreferencePalette;
    final foregroundColor = isActive
        ? const Color(0xFFFFB347)
        : Colors.white.withValues(alpha: 0.90);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: layout.menuMinHeight),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: layout.cardPadding,
              vertical: layout.cardPadding - 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(layout.cardRadius),
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.24),
                        AppColors.accent.withValues(alpha: 0.10),
                      ],
                    )
                  : matchesPreferencePalette
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.03),
                            AppColors.accent.withValues(alpha: 0.07),
                          ],
                        )
                      : null,
              color: isActive
                  ? null
                  : matchesPreferencePalette
                      ? null
                      : Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.20)
                    : matchesPreferencePalette
                        ? AppColors.accent.withValues(alpha: 0.20)
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: layout.iconBoxSize,
                  height: layout.iconBoxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFB02E), Color(0xFFF98C06)],
                          )
                        : null,
                    color: isActive
                        ? null
                        : matchesPreferencePalette
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.04),
                  ),
                  child: iconWidget ??
                      Icon(
                        icon,
                        color: isActive
                            ? Colors.white
                            : matchesPreferencePalette
                                ? AppColors.accent
                                : foregroundColor,
                        size: layout.iconBoxSize * 0.48,
                      ),
                ),
                SizedBox(width: layout.profileGap),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: labelFontSize ?? layout.menuLabelSize,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : matchesPreferencePalette
                              ? FontWeight.w600
                              : FontWeight.w500,
                      height: 1.2,
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

class _DrawerFooterAction extends StatelessWidget {
  const _DrawerFooterAction({
    required this.layout,
    required this.icon,
    required this.onTap,
    this.isAccent = false,
  });

  final _AppDrawerLayout layout;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: layout.footerButtonSize,
          height: layout.footerButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isAccent
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB347), Color(0xFFF98C06)],
                  )
                : null,
            color: isAccent ? null : Colors.white.withValues(alpha: 0.04),
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: layout.footerButtonSize * 0.38,
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFA726), Color(0xFFF98C06)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppColors.accent.withValues(alpha: 0.42),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.96),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.86)
                            : AppColors.accent.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.accent.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  color: isSelected ? Colors.white : AppColors.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}

const List<_LanguageOption> _languageOptions = [
  _LanguageOption(code: 'ru', label: 'Русский'),
  _LanguageOption(code: 'en', label: 'English'),
  _LanguageOption(code: 'kk', label: 'Қазақша'),
];
