import 'package:flutter/material.dart';

import '../../features/notifications/presentation/notification_unread_badge.dart';
import 'app_colors.dart';

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
    final scale = _scaleFor(context);
    final resolvedHeight = height ?? (76 * scale).clamp(68.0, 84.0);
    final resolvedHorizontalPadding =
        horizontalPadding ?? (24 * scale).clamp(18.0, 26.0);
    final resolvedTopPadding = topPadding ?? (14 * scale).clamp(12.0, 16.0);
    final resolvedBottomPadding =
        bottomPadding ?? (14 * scale).clamp(12.0, 16.0);
    final buttonSize = (48 * scale).clamp(42.0, 52.0);
    final backIconSize = (28 * scale).clamp(24.0, 30.0);
    final notificationIconSize = (28 * scale).clamp(24.0, 30.0);
    final titleSize = (28 * scale).clamp(22.0, 30.0);

    return Container(
      height: resolvedHeight,
      padding: EdgeInsets.fromLTRB(
        resolvedHorizontalPadding,
        resolvedTopPadding,
        resolvedHorizontalPadding,
        resolvedBottomPadding,
      ),
      decoration: BoxDecoration(
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: Color(0xFF3A270F)))
            : null,
      ),
      child: Row(
        children: [
          _AppListHeaderButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            background: Colors.transparent,
            size: buttonSize,
            iconSize: backIconSize,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: onBackTap,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8 * scale),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          NotificationUnreadBadge(
            child: _AppListHeaderButton(
              icon: Icons.notifications_outlined,
              color: AppColors.accent,
              background: const Color(0xFF3A2308),
              size: buttonSize,
              iconSize: notificationIconSize,
              tooltip: notificationsTooltip,
              onTap: onNotificationsTap,
            ),
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
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
