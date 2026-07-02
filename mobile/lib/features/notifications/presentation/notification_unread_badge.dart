import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../../providers/notification_badge_provider.dart';

class NotificationUnreadBadge extends StatefulWidget {
  const NotificationUnreadBadge({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationUnreadBadge> createState() =>
      _NotificationUnreadBadgeState();
}

class _NotificationUnreadBadgeState extends State<NotificationUnreadBadge>
    with WidgetsBindingObserver {
  NotificationBadgeProvider? _provider;
  bool _requestedInitialRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = _maybeReadNotificationBadgeProvider(context);
    if (!_requestedInitialRefresh) {
      _requestedInitialRefresh = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_provider?.refresh());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_provider?.refresh(forceRefresh: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _maybeWatchNotificationBadgeProvider(context);
    final count = provider?.unreadCount ?? 0;
    if (count <= 0) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          key: const ValueKey('notification-unread-badge'),
          top: -3,
          right: -3,
          child: _NavBadge(label: _badgeLabel(count)),
        ),
      ],
    );
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final minWidth = label.length > 2 ? 30.0 : 22.0;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Container(
        height: 22,
        alignment: Alignment.center,
        padding: const AppEdgeInsets.symmetric(horizontal: 5),
        decoration: AppBoxDecoration(
          color: colors.primary,
          borderRadius: AppBorderRadius.circular(999),
          border: Border.all(color: colors.surface, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          strutStyle: const StrutStyle(
            fontSize: 10,
            height: 1,
            forceStrutHeight: true,
          ),
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ),
    );
  }
}

String _badgeLabel(int count) {
  if (count > 99) {
    return '99+';
  }
  return '$count';
}

NotificationBadgeProvider? _maybeReadNotificationBadgeProvider(
  BuildContext context,
) {
  try {
    return context.read<NotificationBadgeProvider>();
  } on ProviderNotFoundException {
    return null;
  }
}

NotificationBadgeProvider? _maybeWatchNotificationBadgeProvider(
  BuildContext context,
) {
  try {
    return context.watch<NotificationBadgeProvider>();
  } on ProviderNotFoundException {
    return null;
  }
}
