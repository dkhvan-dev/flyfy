import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../features/notifications/presentation/notification_unread_badge.dart';

class AppNotificationHeaderButton extends StatelessWidget {
  const AppNotificationHeaderButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    this.size = 44,
    this.iconSize,
    this.icon = Icons.notifications_none_rounded,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final double? iconSize;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final effectiveIconSize = iconSize ?? (size < 46 ? 20.0 : 22.0);

    return NotificationUnreadBadge(
      child: Tooltip(
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
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(icon, color: colors.primary, size: effectiveIconSize),
            ),
          ),
        ),
      ),
    );
  }
}
