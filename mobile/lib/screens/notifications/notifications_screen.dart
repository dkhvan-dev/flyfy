import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/time/app_time.dart';
import '../../features/notifications/data/notification_api.dart';
import '../../features/notifications/utils/notification_visibility.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/notification_badge_provider.dart';

class NotificationsOverviewScreen extends StatefulWidget {
  const NotificationsOverviewScreen({super.key, this.notificationApi});

  final NotificationInboxClient? notificationApi;

  @override
  State<NotificationsOverviewScreen> createState() =>
      _NotificationsOverviewScreenState();
}

class _NotificationsOverviewScreenState
    extends State<NotificationsOverviewScreen> {
  late final NotificationInboxClient _notificationApi =
      widget.notificationApi ?? NotificationApi();
  late Future<List<NotificationCategorySummary>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
  }

  Future<List<NotificationCategorySummary>> _loadCategories() async {
    final categories = await _notificationApi.listNotificationCategories();
    return visibleNotificationCategories(categories);
  }

  Future<void> _refresh() async {
    final badgeProvider = _notificationBadgeProvider(context);
    final nextFuture = _loadCategories();
    setState(() {
      _categoriesFuture = nextFuture;
    });
    await nextFuture;
    await badgeProvider?.refresh(forceRefresh: true);
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
              color: AppPalette.primary,
              backgroundColor: AppPalette.surfaceCool,
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
    this.notificationApi,
  });

  final String category;
  final NotificationCategorySummary? initialSummary;
  final NotificationInboxClient? notificationApi;

  @override
  State<NotificationCategoryScreen> createState() =>
      _NotificationCategoryScreenState();
}

class _NotificationCategoryScreenState
    extends State<NotificationCategoryScreen> {
  static const _visibleReadCoverageThreshold = 0.55;
  static const _visibleReadDebounce = Duration(milliseconds: 120);

  late final NotificationInboxClient _notificationApi =
      widget.notificationApi ?? NotificationApi();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  final Map<String, GlobalKey> _notificationReadKeys = {};
  final Map<String, DateTime> _locallyReadAt = {};
  final Set<String> _markingReadNotificationIds = {};
  late Future<List<UserNotification>> _notificationsFuture;
  List<UserNotification> _renderedNotifications = const [];
  Timer? _visibleReadTimer;
  bool _visibleReadCheckScheduled = false;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  @override
  void dispose() {
    _visibleReadTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<UserNotification>> _loadNotifications() {
    return _notificationApi
        .listNotifications(category: widget.category)
        .then(visibleUserNotifications);
  }

  Future<void> _refresh() async {
    final nextFuture = _loadNotifications();
    setState(() {
      _notificationsFuture = nextFuture;
    });
    await nextFuture;
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification ||
        notification is UserScrollNotification) {
      _scheduleVisibleReadCheck(delay: _visibleReadDebounce);
    }
  }

  void _trackRenderedNotifications(List<UserNotification> notifications) {
    _renderedNotifications = notifications;
    final visibleIds = {
      for (final notification in notifications)
        if (notification.id.trim().isNotEmpty) notification.id.trim(),
    };
    _notificationReadKeys.removeWhere((id, _) => !visibleIds.contains(id));
    _scheduleVisibleReadCheck();
  }

  void _scheduleVisibleReadCheck({Duration delay = Duration.zero}) {
    if (!mounted) {
      return;
    }
    _visibleReadTimer?.cancel();
    if (delay > Duration.zero) {
      _visibleReadTimer = Timer(delay, _queueVisibleReadCheck);
      return;
    }
    _queueVisibleReadCheck();
  }

  void _queueVisibleReadCheck() {
    if (_visibleReadCheckScheduled) {
      return;
    }
    _visibleReadCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibleReadCheckScheduled = false;
      if (!mounted) {
        return;
      }
      _markVisibleNotificationsRead();
    });
  }

  void _markVisibleNotificationsRead() {
    final viewportContext = _scrollViewKey.currentContext;
    final viewportRenderObject = viewportContext?.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      return;
    }

    final viewportOrigin = viewportRenderObject.localToGlobal(Offset.zero);
    final viewportRect = viewportOrigin & viewportRenderObject.size;
    for (final notification in _renderedNotifications) {
      final notificationId = notification.id.trim();
      if (notificationId.isEmpty ||
          _isEffectivelyRead(notification) ||
          _markingReadNotificationIds.contains(notificationId)) {
        continue;
      }
      final key = _notificationReadKeys[notificationId];
      final tileRenderObject = key?.currentContext?.findRenderObject();
      if (tileRenderObject is! RenderBox || !tileRenderObject.hasSize) {
        continue;
      }
      final tileOrigin = tileRenderObject.localToGlobal(Offset.zero);
      final tileRect = tileOrigin & tileRenderObject.size;
      final intersection = tileRect.intersect(viewportRect);
      if (intersection.isEmpty) {
        continue;
      }
      final visibleCoverage = intersection.height / tileRect.height;
      if (visibleCoverage >= _visibleReadCoverageThreshold) {
        unawaited(_markNotificationReadFromVisibility(notificationId));
      }
    }
  }

  Future<void> _markNotificationReadFromVisibility(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();
    if (normalizedId.isEmpty ||
        _locallyReadAt.containsKey(normalizedId) ||
        _markingReadNotificationIds.contains(normalizedId)) {
      return;
    }

    final badgeProvider = _notificationBadgeProvider(context);
    _markingReadNotificationIds.add(normalizedId);
    try {
      await _notificationApi.markNotificationRead(notificationId: normalizedId);
      if (!mounted) {
        return;
      }
      setState(() {
        _locallyReadAt[normalizedId] = DateTime.now().toUtc();
      });
      unawaited(badgeProvider?.refresh(forceRefresh: true));
    } catch (_) {
      // Visibility-based read sync is best effort; the next focus/scroll will retry.
    } finally {
      _markingReadNotificationIds.remove(normalizedId);
    }
  }

  bool _isEffectivelyRead(UserNotification notification) {
    final notificationId = notification.id.trim();
    return notification.isRead ||
        notificationId.isNotEmpty && _locallyReadAt.containsKey(notificationId);
  }

  UserNotification _effectiveNotification(UserNotification notification) {
    final notificationId = notification.id.trim();
    final readAt = notificationId.isEmpty
        ? null
        : _locallyReadAt[notificationId];
    if (readAt == null || notification.isRead) {
      return notification;
    }
    return UserNotification(
      id: notification.id,
      category: notification.category,
      priority: notification.priority,
      title: notification.title,
      body: notification.body,
      imageUrl: notification.imageUrl,
      deepLink: notification.deepLink,
      data: notification.data,
      createdAt: notification.createdAt,
      readAt: readAt,
    );
  }

  GlobalKey _notificationReadKey(String notificationId) {
    return _notificationReadKeys.putIfAbsent(notificationId, GlobalKey.new);
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

  Future<void> _openDeepLink(UserNotification notification) async {
    final deepLink = notification.deepLink.trim();
    if (deepLink.isEmpty ||
        !deepLink.startsWith('/') ||
        deepLink.startsWith('//')) {
      return;
    }
    final notificationId = notification.id.trim();
    if (!_isEffectivelyRead(notification) && notificationId.isNotEmpty) {
      try {
        await _notificationApi.markNotificationRead(
          notificationId: notificationId,
        );
      } catch (_) {
        // Opening the destination matters more than blocking on read state.
      }
    }
    if (!mounted) {
      return;
    }
    await context.push(deepLink);
    if (mounted) {
      await _refresh();
    }
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
            final notifications = (snapshot.data ?? const [])
                .map(_effectiveNotification)
                .toList(growable: false);
            _trackRenderedNotifications(notifications);
            final hasUnread = notifications.any(
              (notification) => !_isEffectivelyRead(notification),
            );
            return RefreshIndicator(
              color: AppPalette.primary,
              backgroundColor: AppPalette.surfaceCool,
              onRefresh: _refresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _handleScrollNotification(notification);
                  return false;
                },
                child: CustomScrollView(
                  key: _scrollViewKey,
                  controller: _scrollController,
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
                                      color: AppPalette.backgroundWarm,
                                    ),
                                  )
                                : const Icon(Icons.done_all_rounded),
                            label: Text(l10n.notificationsReadAll),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.primary,
                              disabledBackgroundColor: AppPalette.white
                                  .withValues(alpha: 0.08),
                              foregroundColor: AppPalette.textPrimary,
                              disabledForegroundColor: AppPalette.textCaption,
                              minimumSize: const Size(0, 44),
                              padding: const AppEdgeInsets.symmetric(
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
                      SliverToBoxAdapter(
                        child: _NotificationsPageShell(
                          child: Padding(
                            padding: const AppEdgeInsets.symmetric(
                              vertical: 48,
                            ),
                            child: _StateMessage(
                              icon: Icons.cloud_off_rounded,
                              title: l10n.notificationsLoadFailedTitle,
                              subtitle: l10n.notificationsLoadFailedSubtitle,
                              actionLabel: l10n.retry,
                              onAction: _refresh,
                            ),
                          ),
                        ),
                      )
                    else if (notifications.isEmpty)
                      SliverToBoxAdapter(
                        child: _NotificationsPageShell(
                          child: Padding(
                            padding: const AppEdgeInsets.symmetric(
                              vertical: 48,
                            ),
                            child: _StateMessage(
                              icon: meta.icon,
                              title: l10n.notificationsCategoryEmptyTitle,
                              subtitle: l10n.notificationsCategoryEmptySubtitle,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _NotificationsPageShell(
                          child: Column(
                            children: [
                              for (final notification in notifications) ...[
                                KeyedSubtree(
                                  key: _notificationReadKey(notification.id),
                                  child: _NotificationTile(
                                    notification: notification,
                                    meta: meta,
                                    onTap: () =>
                                        unawaited(_openDeepLink(notification)),
                                  ),
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
      backgroundColor: AppPalette.backgroundWarm,
      body: DecoratedBox(
        decoration: const AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPalette.warmSurface05,
              AppPalette.warmInk19,
              AppPalette.warmInk02,
            ],
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
              padding: AppEdgeInsets.fromLTRB(
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
                    style: const AppTextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const AppTextStyle(
                      color: AppPalette.textCoolSecondary,
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
    final latestText = _localizedNotificationText(context, latest, meta);
    final eventTimeLabel = _notificationEventTimeLabel(context, latest);

    return _InteractivePanel(
      key: ValueKey('notification-category-${summary.category}'),
      onTap: onTap,
      isHighlighted: summary.hasUnread,
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
                      style: const AppTextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (summary.hasUnread)
                      _UnreadBadge(
                        label: _notificationCategoryUnreadBadgeLabel(
                          l10n,
                          summary.unreadCount,
                        ),
                        semanticLabel: l10n.notificationsUnreadCount(
                          summary.unreadCount,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  latestText.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (latestText.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    latestText.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const AppTextStyle(
                      color: AppPalette.textCoolSecondary,
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
                    style: const AppTextStyle(
                      color: AppPalette.textCoolSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _formatRelativeTime(context, latest.createdAt),
                  style: const AppTextStyle(
                    color: AppPalette.textCaption,
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
            color: AppPalette.textCaption,
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
    final l10n = AppLocalizations.of(context)!;
    final localized = _localizedNotificationText(context, notification, meta);
    final eventTimeLabel = _notificationEventTimeLabel(context, notification);
    final isUnread = !notification.isRead;

    return _InteractivePanel(
      key: ValueKey('notification-card-${notification.id}'),
      onTap: onTap,
      isHighlighted: isUnread,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryIcon(meta: meta, hasUnread: isUnread),
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
                            localized.title,
                            style: AppTextStyle(
                              color: notification.isRead
                                  ? AppPalette.textCoolSecondary
                                  : AppPalette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 9,
                            height: 9,
                            margin: const AppEdgeInsets.only(top: 6),
                            decoration: AppBoxDecoration(
                              color: AppPalette.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.primary.withValues(
                                    alpha: 0.36,
                                  ),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _NotificationInfoChip(
                          icon: notification.priority == 'high'
                              ? Icons.bolt_rounded
                              : Icons.schedule_rounded,
                          label: _formatRelativeTime(
                            context,
                            notification.createdAt,
                          ),
                          isAccent: notification.priority == 'high',
                        ),
                        if (notification.priority == 'high')
                          _NotificationInfoChip(
                            icon: Icons.priority_high_rounded,
                            label: l10n.notificationsPriorityHigh,
                            isAccent: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (localized.body.isNotEmpty) ...[
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: AppBoxDecoration(
                color: AppPalette.surfaceCool.withValues(alpha: 0.48),
                borderRadius: AppBorderRadius.circular(16),
                border: Border.all(
                  color: AppPalette.primary.withValues(alpha: 0.10),
                ),
              ),
              child: Padding(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Text(
                  localized.body,
                  style: const AppTextStyle(
                    color: AppPalette.textCoolSecondary,
                    fontSize: 14,
                    height: 1.42,
                  ),
                ),
              ),
            ),
          ],
          if (eventTimeLabel != null) ...[
            const SizedBox(height: 10),
            _NotificationEventTimeBlock(label: eventTimeLabel),
          ],
        ],
      ),
    );
  }
}

class _LocalizedNotificationText {
  const _LocalizedNotificationText({required this.title, required this.body});

  final String title;
  final String body;
}

NotificationBadgeProvider? _notificationBadgeProvider(BuildContext context) {
  try {
    return context.read<NotificationBadgeProvider>();
  } on ProviderNotFoundException {
    return null;
  }
}

_LocalizedNotificationText _localizedNotificationText(
  BuildContext context,
  UserNotification notification,
  _NotificationCategoryMeta meta,
) {
  final l10n = AppLocalizations.of(context)!;
  final localizedTitle = _localizedPayloadValue(
    context,
    notification.data,
    'title',
  );
  final localizedBody = _localizedPayloadValue(
    context,
    notification.data,
    'body',
  );
  if (localizedTitle != null || localizedBody != null) {
    return _LocalizedNotificationText(
      title: localizedTitle ?? _fallbackNotificationTitle(notification, meta),
      body: localizedBody ?? notification.body.trim(),
    );
  }

  final type = _notificationTemplateKey(notification).replaceAll('-', '_');
  final actor = _notificationActorName(l10n, notification);
  switch (type) {
    case 'story_like':
    case 'story_liked':
    case 'story_reaction':
      return _LocalizedNotificationText(
        title: l10n.notificationsStoryLikeTitle(actor),
        body: l10n.notificationsStoryLikeBody,
      );
    case 'story_reply':
    case 'story_response':
    case 'story_message':
      return _LocalizedNotificationText(
        title: l10n.notificationsStoryReplyTitle(actor),
        body: l10n.notificationsStoryReplyBody,
      );
    case 'post_like':
    case 'post_liked':
    case 'post_reaction':
      return _LocalizedNotificationText(
        title: l10n.notificationsPostLikeTitle(actor),
        body:
            _notificationContentTitle(notification) ??
            l10n.notificationsPostLikeBody,
      );
    case 'post_comment':
    case 'post_commented':
    case 'comment':
      return _LocalizedNotificationText(
        title: l10n.notificationsPostCommentTitle(actor),
        body:
            _notificationContentTitle(notification) ??
            l10n.notificationsPostCommentBody,
      );
    case 'chat_message':
    case 'message':
      return _LocalizedNotificationText(
        title: l10n.notificationsChatMessageTitle(actor),
        body: notification.body.trim().isEmpty
            ? l10n.notificationsChatMessageBody
            : notification.body.trim(),
      );
    case 'support_ticket_replied':
    case 'support_agent_replied':
    case 'support_replied':
    case 'ticket_replied':
      return _LocalizedNotificationText(
        title: l10n.notificationsSupportRepliedTitle,
        body: l10n.notificationsSupportRepliedBody,
      );
    case 'support_ticket_created':
    case 'support_ticket_updated':
    case 'support_ticket_resolved':
    case 'support_request_updated':
    case 'ticket_created':
    case 'ticket_updated':
    case 'ticket_resolved':
      return _LocalizedNotificationText(
        title: l10n.notificationsSupportUpdatedTitle,
        body: l10n.notificationsSupportUpdatedBody,
      );
    case 'activity_joined':
    case 'activity_join':
    case 'participant_joined':
      return _LocalizedNotificationText(
        title: l10n.notificationsActivityJoinedTitle(actor),
        body:
            _notificationActivityTitle(notification) ??
            l10n.notificationsActivityJoinedBody,
      );
    case 'participant_waitlisted':
      return _LocalizedNotificationText(
        title: l10n.notificationsActivityParticipantWaitlistedTitle,
        body: l10n.notificationsActivityParticipantWaitlistedBody,
      );
    case 'participant_left':
      return _LocalizedNotificationText(
        title: l10n.notificationsActivityParticipantLeftTitle,
        body: l10n.notificationsActivityParticipantLeftBody,
      );
    case 'participant_late_cancelled':
      return _LocalizedNotificationText(
        title: l10n.notificationsActivityLateCancellationTitle,
        body: l10n.notificationsActivityLateCancellationBody,
      );
    case 'activity_cancelled':
      final activityTitle = _notificationActivityTitle(notification);
      return _LocalizedNotificationText(
        title: l10n.notificationsActivityCancelledTitle,
        body: activityTitle == null
            ? l10n.notificationsActivityCancelledBodyGeneric
            : l10n.notificationsActivityCancelledBody(activityTitle),
      );
    case 'activity_confirmed':
      return _LocalizedNotificationText(
        title: l10n.notificationsActivityConfirmedTitle,
        body: l10n.notificationsActivityConfirmedBody,
      );
    case 'activity_completed':
      return _LocalizedNotificationText(
        title: l10n.notificationsActivityCompletedTitle,
        body: l10n.notificationsActivityCompletedBody,
      );
    case 'booking_created':
    case 'excursion_booking_created':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionBookingCreatedTitle,
        body: l10n.notificationsExcursionBookingCreatedBody,
      );
    case 'booking_cancelled_by_tourist':
    case 'excursion_booking_cancelled':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionBookingCancelledTitle,
        body: l10n.notificationsExcursionBookingCancelledBody,
      );
    case 'booking_guests_updated':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionGuestsUpdatedTitle,
        body: l10n.notificationsExcursionGuestsUpdatedBody,
      );
    case 'attendance_checked_in':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionAttendanceTitle,
        body: l10n.notificationsExcursionAttendanceBody,
      );
    case 'schedule_slot_cancelled':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionCancelledTitle,
        body: l10n.notificationsExcursionCancelledBody,
      );
    case 'schedule_slot_closed':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionStartsSoonTitle,
        body: l10n.notificationsExcursionStartsSoonBody,
      );
    case 'schedule_slot_completed':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionCompletedTitle,
        body: l10n.notificationsExcursionCompletedBody,
      );
    case 'moderation_approved':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionPublishedTitle,
        body: l10n.notificationsExcursionPublishedBody,
      );
    case 'moderation_rejected':
      return _LocalizedNotificationText(
        title: l10n.notificationsExcursionRejectedTitle,
        body: l10n.notificationsExcursionRejectedBody,
      );
    default:
      return _LocalizedNotificationText(
        title: _fallbackNotificationTitle(notification, meta),
        body: notification.body.trim(),
      );
  }
}

String? _localizedPayloadValue(
  BuildContext context,
  Map<String, String> data,
  String baseKey,
) {
  final locale = Localizations.localeOf(context);
  final languageCode = locale.languageCode.toLowerCase();
  final languageTag = locale.toLanguageTag().toLowerCase();
  final normalizedTag = languageTag.replaceAll('-', '_');
  final candidates = [
    '$baseKey.$languageTag',
    '$baseKey.$languageCode',
    '${baseKey}_$normalizedTag',
    '${baseKey}_$languageCode',
    '$baseKey${_capitalizeAscii(languageCode)}',
    'localized${_capitalizeAscii(baseKey)}${_capitalizeAscii(languageCode)}',
  ];
  for (final key in candidates) {
    final value = data[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String _notificationTemplateKey(UserNotification notification) {
  for (final key in const [
    'templateKey',
    'template',
    'activityEvent',
    'excursionEvent',
    'chatEvent',
    'feedEvent',
    'supportEvent',
    'eventType',
    'event',
    'notificationType',
    'type',
    'action',
  ]) {
    final raw = notification.data[key]?.trim().toLowerCase();
    if (raw != null && raw.isNotEmpty) {
      return raw.replaceAll('.', '_').replaceAll(':', '_');
    }
  }
  return _legacyNotificationTemplateKey(notification);
}

String _legacyNotificationTemplateKey(UserNotification notification) {
  final title = notification.title.trim().toLowerCase();
  return switch (title) {
    'activity cancelled' => 'activity_cancelled',
    'activity confirmed' => 'activity_confirmed',
    'activity completed' => 'activity_completed',
    'new participant joined' => 'participant_joined',
    'participant joined the waitlist' => 'participant_waitlisted',
    'participant left activity' => 'participant_left',
    'late cancellation' => 'participant_late_cancelled',
    'new excursion booking' => 'booking_created',
    'excursion booking cancelled' => 'booking_cancelled_by_tourist',
    'booking guests updated' => 'booking_guests_updated',
    'traveler checked in' => 'attendance_checked_in',
    'excursion cancelled' => 'schedule_slot_cancelled',
    'excursion starts soon' => 'schedule_slot_closed',
    'how was your excursion?' => 'schedule_slot_completed',
    'excursion published' => 'moderation_approved',
    'excursion needs changes' => 'moderation_rejected',
    'support replied' => 'support_ticket_replied',
    'support replied to your ticket' => 'support_ticket_replied',
    'support updated your request' => 'support_ticket_updated',
    _ => '',
  };
}

String _notificationActorName(
  AppLocalizations l10n,
  UserNotification notification,
) {
  for (final key in const [
    'actorDisplayName',
    'actorNickname',
    'actorName',
    'senderDisplayName',
    'senderName',
    'userDisplayName',
    'userNickname',
    'username',
    'fromUserName',
  ]) {
    final raw = notification.data[key]?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
  }
  final parsed = _actorNameFromLegacyBody(notification.body);
  if (parsed != null) return parsed;
  return l10n.notificationsSomeone;
}

String? _actorNameFromLegacyBody(String body) {
  final value = body.trim();
  if (value.isEmpty) return null;
  const suffixes = [
    ' нравится ваша история',
    ' liked your story',
    ' liked your post',
    ' прокомментировал ваш пост',
    ' commented on your post',
  ];
  for (final suffix in suffixes) {
    if (value.endsWith(suffix) && value.length > suffix.length) {
      return value.substring(0, value.length - suffix.length).trim();
    }
  }
  return null;
}

String? _notificationContentTitle(UserNotification notification) {
  for (final key in const ['postTitle', 'storyCaption', 'contentTitle']) {
    final raw = notification.data[key]?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
  }
  return null;
}

String? _notificationActivityTitle(UserNotification notification) {
  for (final key in const ['activityTitle', 'eventTitle', 'title']) {
    final raw = notification.data[key]?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
  }
  return _activityTitleFromLegacyBody(notification.body);
}

String? _activityTitleFromLegacyBody(String body) {
  final value = body.trim();
  if (value.isEmpty) return null;
  const suffixes = [
    ' was cancelled.',
    ' is confirmed.',
    ' is complete. You can review your experience.',
    ' has a new participant.',
    ' has a new waitlisted participant.',
    ' has one fewer participant.',
  ];
  for (final suffix in suffixes) {
    if (value.endsWith(suffix) && value.length > suffix.length) {
      return value.substring(0, value.length - suffix.length).trim();
    }
  }
  return null;
}

String _fallbackNotificationTitle(
  UserNotification notification,
  _NotificationCategoryMeta meta,
) {
  final title = notification.title.trim();
  if (title.isNotEmpty) return title;
  final body = notification.body.trim();
  if (body.isNotEmpty) return body;
  return meta.label;
}

String _capitalizeAscii(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

class _NotificationInfoChip extends StatelessWidget {
  const _NotificationInfoChip({
    required this.icon,
    required this.label,
    this.isAccent = false,
  });

  final IconData icon;
  final String label;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final color = isAccent ? AppPalette.primary : AppPalette.textCaption;
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: color.withValues(alpha: isAccent ? 0.14 : 0.08),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationEventTimeBlock extends StatelessWidget {
  const _NotificationEventTimeBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.circular(14),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.event_available_rounded,
              color: AppPalette.primary,
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const AppTextStyle(
                  color: AppPalette.textCoolSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractivePanel extends StatelessWidget {
  const _InteractivePanel({
    super.key,
    required this.child,
    required this.onTap,
    this.isHighlighted = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final borderColor = isHighlighted
        ? AppPalette.primary.withValues(alpha: 0.34)
        : AppPalette.white.withValues(alpha: 0.08);
    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const AppEdgeInsets.all(16),
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHighlighted
                  ? const [AppPalette.warmSurface51, AppPalette.warmInk102]
                  : const [AppPalette.warmSurface04, AppPalette.warmInk45],
            ),
            borderRadius: AppBorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: AppPalette.black.withValues(alpha: 0.26),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
              if (isHighlighted)
                BoxShadow(
                  color: AppPalette.primary.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

String _notificationCategoryUnreadBadgeLabel(
  AppLocalizations l10n,
  int unreadCount,
) {
  if (unreadCount > 99) {
    return '99+';
  }

  return l10n.notificationsUnreadCount(unreadCount);
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
      decoration: AppBoxDecoration(
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
  const _UnreadBadge({required this.label, this.semanticLabel});

  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: AppPalette.primary.withValues(alpha: 0.14),
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: AppPalette.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Text(
              label,
              style: const AppTextStyle(
                color: AppPalette.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
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
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: AppBoxDecoration(
            color: AppPalette.white.withValues(alpha: 0.055),
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: AppPalette.textPrimary, size: 18),
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
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppPalette.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(icon, color: AppPalette.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const AppTextStyle(
                color: AppPalette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const AppTextStyle(
                color: AppPalette.textCoolSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: AppPalette.backgroundWarm,
                  minimumSize: const Size(0, 46),
                  padding: const AppEdgeInsets.symmetric(horizontal: 18),
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
      padding: const AppEdgeInsets.all(16),
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: alpha.clamp(0.055, 0.09)),
        borderRadius: AppBorderRadius.circular(22),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppBoxDecoration(
              color: AppPalette.white.withValues(alpha: 0.08),
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
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.10),
        borderRadius: AppBorderRadius.circular(999),
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
        color: AppPalette.primary,
      );
    case 'excursion':
    case 'excursions':
    case 'tour':
    case 'tours':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryExcursion,
        icon: Icons.explore_rounded,
        color: AppPalette.primaryLight,
      );
    case 'booking':
    case 'bookings':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryBooking,
        icon: Icons.confirmation_number_rounded,
        color: AppPalette.greenSoft08,
      );
    case 'checklist':
    case 'checklists':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryChecklist,
        icon: Icons.checklist_rounded,
        color: AppPalette.primary,
      );
    case 'chat':
    case 'message':
    case 'messages':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryChat,
        icon: Icons.chat_bubble_rounded,
        color: AppPalette.amberSoft25,
      );
    case 'content':
    case 'story':
    case 'stories':
    case 'post':
    case 'posts':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryContent,
        icon: Icons.auto_stories_rounded,
        color: AppPalette.amberSoft17,
      );
    case 'system':
    case 'security':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategorySystem,
        icon: Icons.verified_user_rounded,
        color: AppPalette.violetLight01,
      );
    case 'support':
    case 'help':
    case 'help_center':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategorySupport,
        icon: Icons.support_agent_rounded,
        color: AppPalette.primary,
      );
    case '':
    case 'general':
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryGeneral,
        icon: Icons.notifications_rounded,
        color: AppPalette.primary,
      );
    default:
      return _NotificationCategoryMeta(
        label: l10n.notificationsCategoryFallback(rawCategory),
        icon: Icons.notifications_rounded,
        color: AppPalette.primary,
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
  final userTimezoneId = context
      .read<HomeLocationProvider>()
      .effectiveLocation
      .timezone;
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
