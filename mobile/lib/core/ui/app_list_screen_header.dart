import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import 'app_notification_header_button.dart';

class AppListScreenHeader extends StatelessWidget {
  const AppListScreenHeader({
    super.key,
    required this.title,
    required this.notificationsTooltip,
    required this.onBackTap,
    required this.onNotificationsTap,
    this.horizontalPadding,
    this.topPadding,
    this.bottomPadding,
    this.height,
    this.showBottomBorder = true,
  });

  final String title;
  final String notificationsTooltip;
  final VoidCallback onBackTap;
  final VoidCallback onNotificationsTap;
  final double? horizontalPadding;
  final double? topPadding;
  final double? bottomPadding;
  final double? height;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final scale = _scaleFor(context);
    final resolvedHeight = height ?? (64 * scale).clamp(58.0, 66.0);
    final resolvedHorizontalPadding =
        horizontalPadding ?? (20 * scale).clamp(16.0, 22.0);
    final resolvedTopPadding = topPadding ?? (10 * scale).clamp(8.0, 11.0);
    final resolvedBottomPadding =
        bottomPadding ?? (10 * scale).clamp(8.0, 11.0);
    final buttonSize = (42 * scale).clamp(38.0, 44.0);
    final backIconSize = (24 * scale).clamp(22.0, 25.0);
    final notificationButtonSize = (40 * scale).clamp(38.0, 40.0);
    final notificationIconSize = (20 * scale).clamp(18.0, 20.0);
    final titleSize = (24 * scale).clamp(20.0, 24.0);

    return Container(
      height: resolvedHeight,
      padding: AppEdgeInsets.fromLTRB(
        resolvedHorizontalPadding,
        resolvedTopPadding,
        resolvedHorizontalPadding,
        resolvedBottomPadding,
      ),
      decoration: AppBoxDecoration(
        border: showBottomBorder
            ? Border(bottom: BorderSide(color: colors.borderSoft))
            : null,
      ),
      child: Row(
        children: [
          _AppListHeaderButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            background: colors.transparent,
            size: buttonSize,
            iconSize: backIconSize,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: onBackTap,
          ),
          Expanded(
            child: Padding(
              padding: AppEdgeInsets.symmetric(horizontal: 8 * scale),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyle(
                  color: colors.textPrimary,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          AppNotificationHeaderButton(
            tooltip: notificationsTooltip,
            onTap: onNotificationsTap,
            size: notificationButtonSize,
            iconSize: notificationIconSize,
          ),
        ],
      ),
    );
  }

  double _scaleFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 320) return 0.86;
    if (width >= 430) return 1.0;
    return (width / 430).clamp(0.86, 1.0);
  }
}

class _AppListHeaderButton extends StatelessWidget {
  const _AppListHeaderButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.size,
    required this.iconSize,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: AppBoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}
