import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../core/network/file_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';

enum AppDrawerActiveItem {
  none,
  myActivities,
  myExcursions,
  myChecklists,
  myStories,
  myStoryArchive,
}

const Map<String, Map<String, String>> _localizedCityNames = {
  'Almaty': {'en': 'Almaty', 'ru': 'Алматы', 'kk': 'Алматы'},
};

String resolveDrawerLocation(UserProfileVm? _, Locale locale) {
  final languageCode = locale.languageCode;
  return _localizedCityNames['Almaty']?[languageCode] ?? 'Almaty';
}

String resolveDrawerIdentityStatus({
  required AppLocalizations l10n,
  required bool isLoggedIn,
  required bool showGuideBadge,
  required UserProfileVm? profile,
  bool isGuideStatusRevoked = false,
  bool suppressGuideFallback = false,
}) {
  if (!isLoggedIn) return l10n.loginButton;
  if (showGuideBadge) return l10n.drawerStatusVerifiedGuide;
  if (isGuideStatusRevoked) return l10n.drawerStatusGuideRevoked;
  if (!suppressGuideFallback && profile?.isGuide == true) {
    return l10n.drawerStatusGuide;
  }
  if (profile?.isProfileCompleted == true) return l10n.drawerStatusTraveler;

  return l10n.drawerStatusCompleteProfile;
}

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({
    super.key,
    required this.l10n,
    required this.isLoggedIn,
    required this.showGuideBadge,
    this.isGuideStatusRevoked = false,
    this.suppressGuideFallback = false,
    required this.profile,
    required this.location,
    required this.activeItem,
    required this.onProfileTap,
    required this.onHomeTap,
    required this.onMyActivitiesTap,
    required this.onMyExcursionsTap,
    this.onMyChecklistsTap,
    required this.onMyStoriesTap,
    required this.onMyStoryArchiveTap,
    required this.onActivitiesTap,
    required this.onLoginTap,
    required this.onLogoutTap,
  });

  final AppLocalizations l10n;
  final bool isLoggedIn;
  final bool showGuideBadge;
  final bool isGuideStatusRevoked;
  final bool suppressGuideFallback;
  final UserProfileVm? profile;
  final String location;
  final AppDrawerActiveItem activeItem;
  final VoidCallback onProfileTap;
  final VoidCallback onHomeTap;
  final VoidCallback onMyActivitiesTap;
  final VoidCallback onMyExcursionsTap;
  final VoidCallback? onMyChecklistsTap;
  final VoidCallback onMyStoriesTap;
  final VoidCallback onMyStoryArchiveTap;
  final VoidCallback onActivitiesTap;
  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final layout = _AppDrawerLayout.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileTitle = isLoggedIn
        ? profile?.preferredName ?? 'Inflap'
        : 'Inflap';
    final identityStatus = resolveDrawerIdentityStatus(
      l10n: l10n,
      isLoggedIn: isLoggedIn,
      showGuideBadge: showGuideBadge,
      profile: profile,
      isGuideStatusRevoked: isGuideStatusRevoked,
      suppressGuideFallback: suppressGuideFallback,
    );
    final headerSemanticLabel = isLoggedIn
        ? '$profileTitle, $identityStatus'
        : '${l10n.authLoginAction}, $identityStatus';
    final avatarText = profile?.initials ?? 'F';
    final avatarUrl = resolvePublicFileContentUrl(
      (profile?.avatarFileId ?? '').trim(),
    );
    return Drawer(
      width: layout.drawerWidth,
      backgroundColor: colors.transparent,
      shadowColor: colors.transparent,
      surfaceTintColor: colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: AppBorderRadius.only(
          topRight: AppRadiusValue.circular(layout.panelRadius),
          bottomRight: AppRadiusValue.circular(layout.panelRadius),
        ),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [colors.background, colors.backgroundDeep]
                  : [colors.backgroundDeep, colors.backgroundWarm],
            ),
            border: isDark ? null : Border.all(color: colors.border),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: colors.black.withValues(alpha: 0.28),
                      blurRadius: 32,
                      offset: const Offset(8, 0),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (isDark)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: AppBoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withValues(alpha: 0.08),
                            colors.transparent,
                            colors.secondary.withValues(alpha: 0.05),
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: AppEdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        layout.topPadding,
                        layout.horizontalPadding,
                        layout.sectionGap,
                      ),
                      child: Semantics(
                        button: true,
                        enabled: true,
                        label: headerSemanticLabel,
                        child: ExcludeSemantics(
                          child: Material(
                            color: colors.transparent,
                            child: InkWell(
                              onTap: isLoggedIn ? onProfileTap : onLoginTap,
                              borderRadius: AppBorderRadius.circular(
                                layout.cardRadius,
                              ),
                              child: Ink(
                                padding: AppEdgeInsets.all(layout.cardPadding),
                                decoration: AppBoxDecoration(
                                  borderRadius: AppBorderRadius.circular(
                                    layout.cardRadius,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colors.surfaceRaised,
                                      isDark
                                          ? colors.surfaceWarm
                                          : colors.surfaceHigh,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: colors.borderPrimary,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: layout.avatarSize,
                                          height: layout.avatarSize,
                                          decoration: AppBoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                colors.primaryContainer,
                                                colors.surfaceWarm,
                                              ],
                                            ),
                                            border: Border.all(
                                              color: colors.primary,
                                              width: 3,
                                            ),
                                            boxShadow: isDark
                                                ? [
                                                    BoxShadow(
                                                      color: colors.primary
                                                          .withValues(
                                                            alpha: 0.16,
                                                          ),
                                                      blurRadius: 20,
                                                      offset: const Offset(
                                                        0,
                                                        8,
                                                      ),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: ClipOval(
                                              child: SizedBox.expand(
                                                child: avatarUrl == null
                                                    ? Center(
                                                        child: Text(
                                                          avatarText,
                                                          style: AppTextStyle(
                                                            color: colors
                                                                .textPrimary,
                                                            fontSize: layout
                                                                .avatarTextSize,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      )
                                                    : Image.network(
                                                        avatarUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, _, _) => Center(
                                                          child: Text(
                                                            avatarText,
                                                            style: AppTextStyle(
                                                              color: colors
                                                                  .textPrimary,
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
                                              decoration: AppBoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    colors.primarySoft,
                                                    colors.primary,
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: colors.surface,
                                                  width: 3,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.verified_rounded,
                                                size:
                                                    layout.avatarBadgeIconSize,
                                                color: colors.textPrimary,
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
                                          Text(
                                            profileTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyle(
                                              color: colors.textPrimary,
                                              fontSize: layout.profileTitleSize,
                                              height: 1.05,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(
                                            height: layout.profileTextGap,
                                          ),
                                          Container(
                                            padding:
                                                const AppEdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                            decoration: AppBoxDecoration(
                                              color: colors.primaryContainer,
                                              borderRadius:
                                                  AppBorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              identityStatus,
                                              style: AppTextStyle(
                                                color: colors.primary,
                                                fontSize: layout.metaLabelSize,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ),
                                          if (!isLoggedIn) ...[
                                            SizedBox(
                                              height: layout.profileTextGap,
                                            ),
                                            Text(
                                              l10n.homeSubtitle,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyle(
                                                color: colors.textSecondary,
                                                fontSize:
                                                    layout.profileSubtitleSize,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: layout.trailingGap),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.primary,
                                      size: layout.trailingIconSize,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: AppEdgeInsets.fromLTRB(
                          layout.horizontalPadding,
                          0,
                          layout.horizontalPadding,
                          layout.sectionGap,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DrawerSectionTitle(
                              title: l10n.homeExploreServices,
                              layout: layout,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.myActivitiesTitle,
                              icon: Icons.event_note_rounded,
                              isActive:
                                  activeItem ==
                                  AppDrawerActiveItem.myActivities,
                              usePreferencePalette: true,
                              onTap: onMyActivitiesTap,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.myExcursionsTitle,
                              icon: Icons.tour_rounded,
                              isActive:
                                  activeItem ==
                                  AppDrawerActiveItem.myExcursions,
                              usePreferencePalette: true,
                              onTap: onMyExcursionsTap,
                            ),
                            if (onMyChecklistsTap != null) ...[
                              SizedBox(height: layout.menuGap),
                              _DrawerMenuItem(
                                layout: layout,
                                label: l10n.travelChecklistRecentTitle,
                                icon: Icons.checklist_rtl_rounded,
                                isActive:
                                    activeItem ==
                                    AppDrawerActiveItem.myChecklists,
                                usePreferencePalette: true,
                                onTap: onMyChecklistsTap!,
                              ),
                            ],
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
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.myStoryArchiveTitle,
                              icon: Icons.auto_awesome_motion_rounded,
                              isActive:
                                  activeItem ==
                                  AppDrawerActiveItem.myStoryArchive,
                              usePreferencePalette: true,
                              onTap: onMyStoryArchiveTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _DrawerPinnedFooter(
                      layout: layout,
                      l10n: l10n,
                      isLoggedIn: isLoggedIn,
                      onLoginTap: onLoginTap,
                      onLogoutTap: onLogoutTap,
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

class _DrawerPinnedFooter extends StatelessWidget {
  const _DrawerPinnedFooter({
    required this.layout,
    required this.l10n,
    required this.isLoggedIn,
    required this.onLoginTap,
    required this.onLogoutTap,
  });

  final _AppDrawerLayout layout;
  final AppLocalizations l10n;
  final bool isLoggedIn;
  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Padding(
      padding: AppEdgeInsets.fromLTRB(
        layout.horizontalPadding,
        0,
        layout.horizontalPadding,
        layout.bottomPadding,
      ),
      child: Container(
        padding: AppEdgeInsets.only(top: layout.footerTopPadding),
        decoration: AppBoxDecoration(
          border: Border(top: BorderSide(color: colors.borderPrimary)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeTitle,
                    style: AppTextStyle(
                      color: colors.primary,
                      fontSize: layout.brandTitleSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.homeSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: colors.textMuted,
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
              icon: isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
              semanticLabel: isLoggedIn
                  ? l10n.logoutButton
                  : l10n.authLoginAction,
              isAccent: !isLoggedIn,
              onTap: isLoggedIn ? onLogoutTap : onLoginTap,
            ),
          ],
        ),
      ),
    );
  }
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
    final colors = AppDesignSystem.colorsFor(context);

    return Text(
      title.toUpperCase(),
      style: AppTextStyle(
        color: colors.textSecondary,
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
    this.isActive = false,
    this.usePreferencePalette = false,
  });

  final _AppDrawerLayout layout;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool usePreferencePalette;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final matchesPreferencePalette = !isActive && usePreferencePalette;
    final foregroundColor = isActive
        ? colors.textPrimary
        : matchesPreferencePalette
        ? colors.secondary
        : colors.textPrimary;

    return Semantics(
      button: true,
      enabled: true,
      selected: isActive,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.circular(layout.cardRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: layout.menuMinHeight),
              child: Ink(
                padding: AppEdgeInsets.symmetric(
                  horizontal: layout.cardPadding,
                  vertical: layout.cardPadding - 2,
                ),
                decoration: AppBoxDecoration(
                  borderRadius: AppBorderRadius.circular(layout.cardRadius),
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [colors.primarySoft, colors.primary],
                        )
                      : matchesPreferencePalette
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.surfaceTeal, colors.surfaceHigh],
                        )
                      : null,
                  color: isActive
                      ? null
                      : matchesPreferencePalette
                      ? null
                      : colors.surfaceRaised,
                  border: Border.all(
                    color: isActive
                        ? colors.borderPrimary
                        : matchesPreferencePalette
                        ? colors.borderSecondary
                        : colors.borderSoft,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: layout.iconBoxSize,
                      height: layout.iconBoxSize,
                      decoration: AppBoxDecoration(
                        borderRadius: AppBorderRadius.circular(18),
                        gradient: isActive
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [colors.primarySoft, colors.primary],
                              )
                            : null,
                        color: isActive
                            ? null
                            : matchesPreferencePalette
                            ? colors.secondaryContainer
                            : colors.surfaceHigh,
                      ),
                      child: Icon(
                        icon,
                        color: isActive
                            ? colors.textPrimary
                            : matchesPreferencePalette
                            ? colors.secondary
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
                        style: AppTextStyle(
                          color: foregroundColor,
                          fontSize: layout.menuLabelSize,
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
        ),
      ),
    );
  }
}

class _DrawerFooterAction extends StatelessWidget {
  const _DrawerFooterAction({
    required this.layout,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.isAccent = false,
  });

  final _AppDrawerLayout layout;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.circular(999),
            child: Ink(
              width: layout.footerButtonSize,
              height: layout.footerButtonSize,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: isAccent ? colors.primary : colors.surfaceHigh,
                border: Border.all(
                  color: isAccent ? colors.borderPrimary : colors.borderSoft,
                ),
                boxShadow: isAccent && isDark
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isAccent ? colors.textPrimary : colors.primary,
                size: layout.footerButtonSize * 0.38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
