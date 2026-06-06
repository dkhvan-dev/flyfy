import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/time/app_time.dart';
import '../../core/ui/app_colors.dart';
import '../../features/notifications/data/notification_api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';

class NotificationsOverviewScreen extends StatefulWidget {
  const NotificationsOverviewScreen({super.key});

  @override
  State<NotificationsOverviewScreen> createState() =>
      _NotificationsOverviewScreenState();
}

class _NotificationsOverviewScreenState
    extends State<NotificationsOverviewScreen> {
  final NotificationInboxClient _notificationApi = NotificationApi();
  late Future<List<NotificationCategorySummary>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _notificationApi.listNotificationCategories();
  }

  Future<void> _refresh() async {
    final nextFuture = _notificationApi.listNotificationCategories();
    setState(() {
      _categoriesFuture = nextFuture;
    });
    await nextFuture;
  }

  Future<void> _openCategory(NotificationCategorySummary summary) async {
    await context.push(
      '/notifications/${Uri.encodeComponent(summary.category)}',
      extra: summary,
    );
    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _NotificationsBackground(
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<NotificationCategorySummary>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            final categories = snapshot.data ?? const [];
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _NotificationsPageShell(
                      child: _NotificationsHeader(
                        title: l10n.notificationsTitle,
                        subtitle: l10n.notificationsSubtitle,
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      categories.isEmpty)
                    const SliverToBoxAdapter(
                      child: _NotificationsPageShell(child: _LoadingList()),
                    )
                  else if (snapshot.hasError && categories.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NotificationsPageShell(
                        child: _StateMessage(
                          icon: Icons.cloud_off_rounded,
                          title: l10n.notificationsLoadFailedTitle,
                          subtitle: l10n.notificationsLoadFailedSubtitle,
                          actionLabel: l10n.retry,
                          onAction: _refresh,
                        ),
                      ),
                    )
                  else if (categories.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NotificationsPageShell(
                        child: _StateMessage(
                          icon: Icons.notifications_none_rounded,
                          title: l10n.notificationsCategoriesEmptyTitle,
                          subtitle: l10n.notificationsCategoriesEmptySubtitle,
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _NotificationsPageShell(
                        child: Column(
                          children: [
                            for (final summary in categories) ...[
                              _NotificationCategoryTile(
                                summary: summary,
                                meta: _categoryMeta(context, summary.category),
                                onTap: () => _openCategory(summary),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NotificationCategoryScreen extends StatefulWidget {
  const NotificationCategoryScreen({
    super.key,
    required this.category,
    this.initialSummary,
  });

  final String category;
  final NotificationCategorySummary? initialSummary;

  @override
  State<NotificationCategoryScreen> createState() =>
      _NotificationCategoryScreenState();
}

class _NotificationCategoryScreenState
    extends State<NotificationCategoryScreen> {
  final NotificationInboxClient _notificationApi = NotificationApi();
  late Future<List<UserNotification>> _notificationsFuture;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<UserNotification>> _loadNotifications() {
    return _notificationApi.listNotifications(category: widget.category);
  }

  Future<void> _refresh() async {
    final nextFuture = _loadNotifications();
    setState(() {
      _notificationsFuture = nextFuture;
    });
    await nextFuture;
  }

  Future<void> _markAllRead() async {
    if (_markingRead) {
      return;
    }
    setState(() {
      _markingRead = true;
    });
    final l10n = AppLocalizations.of(context)!;
    try {
      await _notificationApi.markNotificationCategoryRead(
        category: widget.category,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.notificationsReadAllDone)));
      await _refresh();
    } finally {
      if (mounted) {
        setState(() {
          _markingRead = false;
        });
      }
    }
  }

  void _openDeepLink(UserNotification notification) {
    final deepLink = notification.deepLink.trim();
    if (deepLink.isEmpty ||
        !deepLink.startsWith('/') ||
        deepLink.startsWith('//')) {
      return;
    }
    context.push(deepLink);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meta = _categoryMeta(context, widget.category);

    return _NotificationsBackground(
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<UserNotification>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? const [];
            final hasUnread = notifications.any(
              (notification) => !notification.isRead,
            );
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _NotificationsPageShell(
                      child: _NotificationsHeader(
                        title: meta.label,
                        subtitle: l10n.notificationsSubtitle,
                        action: FilledButton.icon(
                          onPressed: hasUnread && !_markingRead
                              ? _markAllRead
                              : null,
                          icon: _markingRead
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                              : const Icon(Icons.done_all_rounded),
                          label: Text(l10n.notificationsReadAll),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            foregroundColor: AppColors.background,
                            disabledForegroundColor: AppColors.textCaption,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      notifications.isEmpty)
                    const SliverToBoxAdapter(
                      child: _NotificationsPageShell(child: _LoadingList()),
                    )
                  else if (snapshot.hasError && notifications.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NotificationsPageShell(
                        child: _StateMessage(
                          icon: Icons.cloud_off_rounded,
                          title: l10n.notificationsLoadFailedTitle,
                          subtitle: l10n.notificationsLoadFailedSubtitle,
                          actionLabel: l10n.retry,
                          onAction: _refresh,
                        ),
                      ),
                    )
                  else if (notifications.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NotificationsPageShell(
                        child: _StateMessage(
                          icon: meta.icon,
                          title: l10n.notificationsCategoryEmptyTitle,
                          subtitle: l10n.notificationsCategoryEmptySubtitle,
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _NotificationsPageShell(
                        child: Column(
                          children: [
                            for (final notification in notifications) ...[
                              _NotificationTile(
                                notification: notification,
                                meta: meta,
                                onTap: () => _openDeepLink(notification),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsBackground extends StatelessWidget {
  const _NotificationsBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF271A0E), Color(0xFF15100D), Color(0xFF0E0A08)],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _NotificationsPageShell extends StatelessWidget {
  const _NotificationsPageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 380 ? 14.0 : 20.0;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                0,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: action!),
        ],
        const SizedBox(height: 22),
      ],
    );
  }
}

class _NotificationCategoryTile extends StatelessWidget {
  const _NotificationCategoryTile({
    required this.summary,
    required this.meta,
    required this.onTap,
  });

  final NotificationCategorySummary summary;
  final _NotificationCategoryMeta meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final latest = summary.latest;
    final eventTimeLabel = _notificationEventTimeLabel(context, latest);

    return _InteractivePanel(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryIcon(meta: meta, hasUnread: summary.hasUnread),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      meta.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (summary.hasUnread)
                      _UnreadBadge(
                        label: l10n.notificationsUnreadCount(
                          summary.unreadCount,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  latest.title.isEmpty ? latest.body : latest.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (latest.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    latest.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                if (eventTimeLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    eventTimeLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _formatRelativeTime(context, latest.createdAt),
                  style: const TextStyle(
                    color: AppColors.textCaption,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textCaption,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.meta,
    required this.onTap,
  });

  final UserNotification notification;
  final _NotificationCategoryMeta meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = notification.title.isEmpty ? meta.label : notification.title;
    final eventTimeLabel = _notificationEventTimeLabel(context, notification);

    return _InteractivePanel(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryIcon(meta: meta, hasUnread: !notification.isRead),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: notification.isRead
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.38,
                    ),
                  ),
                ],
                if (eventTimeLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    eventTimeLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      notification.priority == 'high'
                          ? Icons.bolt_rounded
                          : Icons.schedule_rounded,
                      color: notification.priority == 'high'
                          ? AppColors.accent
                          : AppColors.textCaption,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _formatRelativeTime(context, notification.createdAt),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textCaption,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractivePanel extends StatelessWidget {
  const _InteractivePanel({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.meta, required this.hasUnread});

  final _NotificationCategoryMeta meta;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: meta.color.withValues(alpha: hasUnread ? 0.20 : 0.10),
        border: Border.all(
          color: meta.color.withValues(alpha: hasUnread ? 0.42 : 0.20),
        ),
      ),
      child: Icon(meta.icon, color: meta.color, size: 23),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(icon, color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 4; index++) ...[
          _SkeletonPanel(delay: index),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    final alpha = 0.055 + (delay * 0.012);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha.clamp(0.055, 0.09)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: _SkeletonLine(height: 14),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.82,
                  child: _SkeletonLine(height: 12),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.34,
                  child: _SkeletonLine(height: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _NotificationCategoryMeta {
  const _NotificationCategoryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

_NotificationCategoryMeta _categoryMeta(
  BuildContext context,
  String rawCategory,
) {
  final l10n = AppLocalizations.of(context)!;
  final category = rawCategory.trim().toLowerCase();
  switch (category) {
    case 'activity':
    case 'activities':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryActivity,
        icon: Icons.groups_2_rounded,
        color: AppColors.accent,
      );
    case 'excursion':
    case 'excursions':
    case 'tour':
    case 'tours':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryExcursion,
        icon: Icons.explore_rounded,
        color: AppColors.accentLight,
      );
    case 'booking':
    case 'bookings':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryBooking,
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFFB6F36C),
      );
    case 'chat':
    case 'message':
    case 'messages':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryChat,
        icon: Icons.chat_bubble_rounded,
        color: const Color(0xFFFFD166),
      );
    case 'system':
    case 'security':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategorySystem,
        icon: Icons.verified_user_rounded,
        color: const Color(0xFFA78BFA),
      );
    case '':
    case 'general':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryGeneral,
        icon: Icons.notifications_rounded,
        color: AppColors.accent,
      );
    default:
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryFallback(rawCategory),
        icon: Icons.notifications_rounded,
        color: AppColors.accent,
      );
  }
}

String _formatRelativeTime(BuildContext context, DateTime createdAt) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final difference = now.difference(createdAt.toLocal());
  if (difference.inMinutes < 1) {
    return l10n.notificationsJustNow;
  }
  if (difference.inHours < 1) {
    return l10n.notificationsMinutesAgo(difference.inMinutes);
  }
  if (difference.inDays < 1) {
    return l10n.notificationsHoursAgo(difference.inHours);
  }
  return l10n.notificationsDaysAgo(difference.inDays);
}

String? _notificationEventTimeLabel(
  BuildContext context,
  UserNotification notification,
) {
  final eventInstant = _notificationEventInstant(notification.data);
  final eventTimezone = _notificationEventTimezone(notification.data);
  if (eventInstant == null || eventTimezone == null) return null;

  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final userTimezoneId = context.read<SessionProvider>().profile?.timezone;
  final primary = formatEventDateTime(
    eventInstant,
    timezoneId: eventTimezone,
    localeName: localeName,
  );
  final secondary = formatUserTimezoneHint(
    instant: eventInstant,
    eventTimezoneId: eventTimezone,
    userTimezoneId: userTimezoneId,
    localeName: localeName,
  );
  if (secondary == null) return primary;
  return '$primary\n${l10n.timeDisplayYourTime(secondary)}';
}

DateTime? _notificationEventInstant(Map<String, String> data) {
  for (final key in const [
    'eventStartAt',
    'startsAt',
    'startAt',
    'scheduledFor',
  ]) {
    final raw = data[key]?.trim();
    if (raw == null || raw.isEmpty) continue;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toUtc();
  }
  return null;
}

String? _notificationEventTimezone(Map<String, String> data) {
  for (final key in const [
    'eventTimezone',
    'timezone',
    'slotTimezone',
    'scheduleTimezone',
  ]) {
    final raw = data[key]?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
  }
  return null;
}
