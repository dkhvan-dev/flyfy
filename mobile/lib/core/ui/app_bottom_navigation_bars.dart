import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../features/chat/models/conversation_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/chat_provider.dart';

enum AppBottomNavItem { home, feed, qr, map, services, chats }

enum AppBottomNavCreateBackgroundStyle { elevated, flat }

class AppBottomNavigationBarStyle {
  const AppBottomNavigationBarStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.activeColor,
    required this.inactiveColor,
    required this.splashColor,
    required this.highlightColor,
    required this.badgeBackgroundColor,
    required this.badgeForegroundColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color activeColor;
  final Color inactiveColor;
  final Color splashColor;
  final Color highlightColor;
  final Color badgeBackgroundColor;
  final Color badgeForegroundColor;

  static AppBottomNavigationBarStyle v2(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return AppBottomNavigationBarStyle(
      backgroundColor: colors.surface,
      borderColor: colors.border,
      activeColor: colors.primary,
      inactiveColor: colors.textMuted,
      splashColor: colors.borderPrimary,
      highlightColor: colors.transparent,
      badgeBackgroundColor: colors.primary,
      badgeForegroundColor: colors.textPrimary,
    );
  }
}

class CommonBottomNavigationBar extends StatelessWidget {
  const CommonBottomNavigationBar({
    super.key,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onMapTap,
    required this.onServicesTap,
    required this.onChatsTap,
    this.activeItem,
    this.onFeedTap,
    this.onCenterCreateTap,
    this.centerCreateSemanticsLabel,
    this.showFeedItem = false,
    this.style,
  });

  final AppBottomNavItem? activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback? onFeedTap;
  final VoidCallback? onCenterCreateTap;
  final VoidCallback onMapTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;
  final String? centerCreateSemanticsLabel;
  final bool showFeedItem;
  final AppBottomNavigationBarStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final useCenterCreate = onCenterCreateTap != null;
    final layout = useCenterCreate
        ? _BottomNavLayout.withCreate(context)
        : _BottomNavLayout.common(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final renderFeedItem = showFeedItem || activeItem == AppBottomNavItem.feed;
    final resolvedStyle = style ?? AppBottomNavigationBarStyle.v2(context);

    return _BottomNavPaintedSafeArea(
      barHeight: layout.barHeight,
      safeBottom: safeBottom,
      decoration: AppBoxDecoration(
        color: resolvedStyle.backgroundColor,
        border: Border(top: BorderSide(color: resolvedStyle.borderColor)),
      ),
      child: Padding(
        padding: AppEdgeInsets.fromLTRB(
          layout.horizontalPadding,
          layout.topPadding,
          layout.horizontalPadding,
          layout.bottomPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavButton(
                layout: layout,
                label: l10n.homeNavHome,
                icon: Icons.home_filled,
                active: activeItem == AppBottomNavItem.home,
                style: resolvedStyle,
                onTap: onHomeTap,
              ),
            ),
            Expanded(
              child: _BottomNavButton(
                layout: layout,
                label: renderFeedItem ? l10n.feedNavLabel : l10n.homeNavQr,
                icon: renderFeedItem
                    ? Icons.dynamic_feed_rounded
                    : Icons.qr_code_2_rounded,
                active:
                    activeItem ==
                    (renderFeedItem
                        ? AppBottomNavItem.feed
                        : AppBottomNavItem.qr),
                style: resolvedStyle,
                onTap: renderFeedItem ? (onFeedTap ?? onQrTap) : onQrTap,
              ),
            ),
            Expanded(
              child: useCenterCreate
                  ? _CreateBottomNavFab(
                      layout: layout,
                      semanticsLabel:
                          centerCreateSemanticsLabel ??
                          l10n.communityProfileCreatePostAction,
                      onTap: onCenterCreateTap!,
                    )
                  : _BottomNavButton(
                      layout: layout,
                      label: l10n.homeNavMap,
                      icon: Icons.map_outlined,
                      active: activeItem == AppBottomNavItem.map,
                      style: resolvedStyle,
                      onTap: onMapTap,
                    ),
            ),
            Expanded(
              child: _BottomNavButton(
                layout: layout,
                label: l10n.servicesSectionTitle,
                icon: Icons.grid_view_rounded,
                active: activeItem == AppBottomNavItem.services,
                style: resolvedStyle,
                onTap: onServicesTap,
              ),
            ),
            Expanded(
              child: _ChatUnreadCountBuilder(
                builder: (context, unreadConversationCount) => _BottomNavButton(
                  layout: layout,
                  label: l10n.homeNavChats,
                  icon: Icons.chat_bubble_outline_rounded,
                  active: activeItem == AppBottomNavItem.chats,
                  style: resolvedStyle,
                  onTap: onChatsTap,
                  badgeCount: unreadConversationCount,
                  badgeKey: const ValueKey('bottom-nav-chats-badge'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateActionBottomNavigationBar extends StatelessWidget {
  const CreateActionBottomNavigationBar({
    super.key,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onCreateTap,
    required this.onServicesTap,
    required this.onChatsTap,
    this.activeItem,
    this.createSemanticsLabel,
    this.backgroundStyle = AppBottomNavCreateBackgroundStyle.elevated,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback onCreateTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;
  final AppBottomNavItem? activeItem;
  final String? createSemanticsLabel;
  final AppBottomNavCreateBackgroundStyle backgroundStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final layout = _BottomNavLayout.withCreate(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final useFlatBackground =
        backgroundStyle == AppBottomNavCreateBackgroundStyle.flat;
    final style = AppBottomNavigationBarStyle.v2(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _BottomNavPaintedSafeArea(
      barHeight: layout.barHeight,
      safeBottom: safeBottom,
      decoration: AppBoxDecoration(
        color: useFlatBackground ? colors.surface : null,
        gradient: useFlatBackground
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.surfaceRaised, colors.surface],
              ),
        border: Border(top: BorderSide(color: colors.borderSoft)),
        boxShadow: useFlatBackground || !isDark
            ? null
            : [
                BoxShadow(
                  color: colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Padding(
        padding: AppEdgeInsets.fromLTRB(
          layout.horizontalPadding,
          layout.topPadding,
          layout.horizontalPadding,
          layout.bottomPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavButton(
                layout: layout,
                label: l10n.homeNavHome,
                icon: Icons.home_filled,
                active: activeItem == AppBottomNavItem.home,
                style: style,
                onTap: onHomeTap,
              ),
            ),
            Expanded(
              child: _BottomNavButton(
                layout: layout,
                label: l10n.homeNavQr,
                icon: Icons.qr_code_2_rounded,
                active: activeItem == AppBottomNavItem.qr,
                style: style,
                onTap: onQrTap,
              ),
            ),
            Expanded(
              child: _CreateBottomNavFab(
                layout: layout,
                semanticsLabel: createSemanticsLabel ?? l10n.createActivityFab,
                onTap: onCreateTap,
              ),
            ),
            Expanded(
              child: _BottomNavButton(
                layout: layout,
                label: l10n.servicesSectionTitle,
                icon: Icons.grid_view_rounded,
                active: activeItem == AppBottomNavItem.services,
                style: style,
                onTap: onServicesTap,
              ),
            ),
            Expanded(
              child: _ChatUnreadCountBuilder(
                builder: (context, unreadConversationCount) => _BottomNavButton(
                  layout: layout,
                  label: l10n.homeNavChats,
                  icon: Icons.chat_bubble_outline_rounded,
                  active: activeItem == AppBottomNavItem.chats,
                  style: style,
                  onTap: onChatsTap,
                  badgeCount: unreadConversationCount,
                  badgeKey: const ValueKey('bottom-nav-chats-badge'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavPaintedSafeArea extends StatelessWidget {
  const _BottomNavPaintedSafeArea({
    required this.barHeight,
    required this.safeBottom,
    required this.decoration,
    required this.child,
  });

  final double barHeight;
  final double safeBottom;
  final Decoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration,
      child: SizedBox(
        height: barHeight + safeBottom,
        child: Padding(
          padding: AppEdgeInsets.only(bottom: safeBottom),
          child: child,
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.layout,
    required this.label,
    required this.icon,
    required this.active,
    required this.style,
    required this.onTap,
    this.badgeCount = 0,
    this.badgeKey,
  });

  final _BottomNavLayout layout;
  final String label;
  final IconData icon;
  final bool active;
  final AppBottomNavigationBarStyle style;
  final VoidCallback onTap;
  final int badgeCount;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    final color = active ? style.activeColor : style.inactiveColor;
    final colors = AppDesignSystem.colorsFor(context);

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(layout.itemRadius),
        splashColor: style.splashColor,
        highlightColor: style.highlightColor,
        child: SizedBox(
          height: layout.itemHeight,
          child: Center(
            child: Padding(
              padding: AppEdgeInsets.symmetric(
                horizontal: layout.itemHorizontalInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: layout.iconSize + 18,
                    height: layout.iconSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, color: color, size: layout.iconSize),
                        if (badgeCount > 0)
                          Positioned(
                            key: badgeKey,
                            top: -5,
                            right: 0,
                            child: _BottomNavBadge(
                              style: style,
                              label: _bottomNavBadgeLabel(badgeCount),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: layout.itemGap),
                  SizedBox(
                    height: layout.labelHeight,
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: AppTextStyle(
                          color: color,
                          fontSize: layout.labelSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          height: 1,
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
    );
  }
}

class _ChatUnreadCountBuilder extends StatefulWidget {
  const _ChatUnreadCountBuilder({required this.builder});

  final Widget Function(BuildContext context, int unreadConversationCount)
  builder;

  @override
  State<_ChatUnreadCountBuilder> createState() =>
      _ChatUnreadCountBuilderState();
}

class _ChatUnreadCountBuilderState extends State<_ChatUnreadCountBuilder>
    with WidgetsBindingObserver {
  ChatProvider? _provider;
  bool _requestedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = _maybeRead<ChatProvider>(context);
    if (!_requestedInitialLoad) {
      _requestedInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_provider?.loadConversations());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_provider?.loadConversations(forceRefresh: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _maybeWatch<ChatProvider>(context);
    final count = _unreadConversationCount(provider?.conversations ?? const []);
    return widget.builder(context, count);
  }
}

class _BottomNavBadge extends StatelessWidget {
  const _BottomNavBadge({required this.style, required this.label});

  final AppBottomNavigationBarStyle style;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: style.badgeBackgroundColor,
          borderRadius: AppBorderRadius.circular(999),
          border: Border.all(color: style.backgroundColor, width: 1.5),
        ),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: style.badgeForegroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

int _unreadConversationCount(List<ConversationVm> conversations) {
  return conversations
      .where((conversation) => conversation.unreadCount > 0)
      .length;
}

String _bottomNavBadgeLabel(int count) {
  if (count > 99) {
    return '99+';
  }
  return '$count';
}

T? _maybeRead<T>(BuildContext context) {
  try {
    return context.read<T>();
  } on ProviderNotFoundException {
    return null;
  }
}

T? _maybeWatch<T>(BuildContext context) {
  try {
    return context.watch<T>();
  } on ProviderNotFoundException {
    return null;
  }
}

class _CreateBottomNavFab extends StatelessWidget {
  const _CreateBottomNavFab({
    required this.layout,
    required this.semanticsLabel,
    required this.onTap,
  });

  final _BottomNavLayout layout;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      key: const ValueKey('bottom-nav-create-action'),
      button: true,
      label: semanticsLabel,
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(layout.itemRadius),
          splashColor: colors.borderPrimary,
          highlightColor: colors.transparent,
          child: SizedBox(
            height: layout.itemHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Ink(
                    width: layout.fabSize,
                    height: layout.fabSize,
                    decoration: AppBoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                      border: Border.all(
                        color: colors.surface,
                        width: layout.fabBorderWidth,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: colors.black.withValues(alpha: 0.24),
                                blurRadius: layout.fabShadowBlur,
                                offset: Offset(0, layout.fabShadowOffsetY),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: colors.textPrimary,
                      size: layout.fabIconSize,
                    ),
                  ),
                  SizedBox(height: layout.itemGap + layout.labelHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavLayout {
  const _BottomNavLayout({
    required this.barHeight,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.itemHeight,
    required this.itemHorizontalInset,
    required this.itemRadius,
    required this.iconSize,
    required this.labelSize,
    required this.labelHeight,
    required this.itemGap,
    required this.centerSlotWidth,
    required this.fabSize,
    required this.fabTopOffset,
    required this.fabBorderWidth,
    required this.fabShadowBlur,
    required this.fabShadowOffsetY,
    required this.fabIconSize,
  });

  factory _BottomNavLayout.common(BuildContext context) {
    final scale = _scaleForWidth(context);
    return _BottomNavLayout(
      barHeight: 78 * scale,
      horizontalPadding: 6 * scale,
      topPadding: 7 * scale,
      bottomPadding: 5 * scale,
      itemHeight: 66 * scale,
      itemHorizontalInset: 2 * scale,
      itemRadius: 16 * scale,
      iconSize: 30 * scale,
      labelSize: 10.5 * scale,
      labelHeight: 11 * scale,
      itemGap: 4 * scale,
      centerSlotWidth: 0,
      fabSize: 0,
      fabTopOffset: 0,
      fabBorderWidth: 0,
      fabShadowBlur: 0,
      fabShadowOffsetY: 0,
      fabIconSize: 0,
    );
  }

  factory _BottomNavLayout.withCreate(BuildContext context) {
    final scale = _scaleForWidth(context);
    return _BottomNavLayout(
      barHeight: 78 * scale,
      horizontalPadding: 6 * scale,
      topPadding: 7 * scale,
      bottomPadding: 5 * scale,
      itemHeight: 66 * scale,
      itemHorizontalInset: 2 * scale,
      itemRadius: 16 * scale,
      iconSize: 30 * scale,
      labelSize: 10.5 * scale,
      labelHeight: 11 * scale,
      itemGap: 4 * scale,
      centerSlotWidth: 0,
      fabSize: 40 * scale,
      fabTopOffset: 0,
      fabBorderWidth: 3 * scale,
      fabShadowBlur: 12 * scale,
      fabShadowOffsetY: 4 * scale,
      fabIconSize: 20 * scale,
    );
  }

  final double barHeight;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double itemHeight;
  final double itemHorizontalInset;
  final double itemRadius;
  final double iconSize;
  final double labelSize;
  final double labelHeight;
  final double itemGap;
  final double centerSlotWidth;
  final double fabSize;
  final double fabTopOffset;
  final double fabBorderWidth;
  final double fabShadowBlur;
  final double fabShadowOffsetY;
  final double fabIconSize;

  static double _scaleForWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width.clamp(320.0, 430.0);
    return (width / 393).clamp(0.9, 1.08);
  }
}
