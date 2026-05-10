import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'app_colors.dart';

enum AppBottomNavItem { home, qr, map, services, chats }

enum AppBottomNavCreateBackgroundStyle { elevated, flat }

class CommonBottomNavigationBar extends StatelessWidget {
  const CommonBottomNavigationBar({
    super.key,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onMapTap,
    required this.onServicesTap,
    required this.onChatsTap,
    this.activeItem,
  });

  final AppBottomNavItem? activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback onMapTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final layout = _BottomNavLayout.common(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: layout.barHeight + safeBottom,
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF3B2818),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
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
                    onTap: onHomeTap,
                  ),
                ),
                Expanded(
                  child: _BottomNavButton(
                    layout: layout,
                    label: l10n.homeNavQr,
                    icon: Icons.qr_code_2_rounded,
                    active: activeItem == AppBottomNavItem.qr,
                    onTap: onQrTap,
                  ),
                ),
                Expanded(
                  child: _BottomNavButton(
                    layout: layout,
                    label: l10n.homeNavMap,
                    icon: Icons.map_outlined,
                    active: activeItem == AppBottomNavItem.map,
                    onTap: onMapTap,
                  ),
                ),
                Expanded(
                  child: _BottomNavButton(
                    layout: layout,
                    label: l10n.servicesSectionTitle,
                    icon: Icons.grid_view_rounded,
                    active: activeItem == AppBottomNavItem.services,
                    onTap: onServicesTap,
                  ),
                ),
                Expanded(
                  child: _BottomNavButton(
                    layout: layout,
                    label: l10n.homeNavChats,
                    icon: Icons.chat_bubble_outline_rounded,
                    active: activeItem == AppBottomNavItem.chats,
                    onTap: onChatsTap,
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

class CreateActionBottomNavigationBar extends StatelessWidget {
  const CreateActionBottomNavigationBar({
    super.key,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onCreateTap,
    required this.onServicesTap,
    required this.onChatsTap,
    this.activeItem,
    this.backgroundStyle = AppBottomNavCreateBackgroundStyle.elevated,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback onCreateTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;
  final AppBottomNavItem? activeItem;
  final AppBottomNavCreateBackgroundStyle backgroundStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final layout = _BottomNavLayout.withCreate(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final useFlatBackground =
        backgroundStyle == AppBottomNavCreateBackgroundStyle.flat;

    return SizedBox(
      height: layout.barHeight + safeBottom,
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: useFlatBackground ? const Color(0xFF3A2818) : null,
            gradient: useFlatBackground
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF422D1B), Color(0xFF3A2818)],
                  ),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
            boxShadow: useFlatBackground
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
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
                    onTap: onHomeTap,
                  ),
                ),
                Expanded(
                  child: _BottomNavButton(
                    layout: layout,
                    label: l10n.homeNavQr,
                    icon: Icons.qr_code_2_rounded,
                    active: activeItem == AppBottomNavItem.qr,
                    onTap: onQrTap,
                  ),
                ),
                Expanded(
                  child: _CreateBottomNavFab(
                    layout: layout,
                    semanticsLabel: l10n.createActivityFab,
                    onTap: onCreateTap,
                  ),
                ),
                Expanded(
                  child: _BottomNavButton(
                    layout: layout,
                    label: l10n.servicesSectionTitle,
                    icon: Icons.grid_view_rounded,
                    active: activeItem == AppBottomNavItem.services,
                    onTap: onServicesTap,
                  ),
                ),
                Expanded(
                  child: _BottomNavButton(
                    layout: layout,
                    label: l10n.homeNavChats,
                    icon: Icons.chat_bubble_outline_rounded,
                    active: activeItem == AppBottomNavItem.chats,
                    onTap: onChatsTap,
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

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.layout,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final _BottomNavLayout layout;
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : const Color(0xFFD8C0A2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.itemRadius),
        splashColor: AppColors.accent.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: layout.itemHeight,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout.itemHorizontalInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: layout.iconSize),
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
                        style: TextStyle(
                          color: color,
                          fontSize: layout.labelSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
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
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(layout.itemRadius),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: layout.itemHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Ink(
                    width: layout.fabSize,
                    height: layout.fabSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF9F05),
                      border: Border.all(
                        color: const Color(0xFF25170C),
                        width: layout.fabBorderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.24),
                          blurRadius: layout.fabShadowBlur,
                          offset: Offset(0, layout.fabShadowOffsetY),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: const Color(0xFFFFF6EA),
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
