import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/notifications/data/notification_api.dart';
import 'package:inflap/features/notifications/presentation/notification_unread_badge.dart';
import 'package:inflap/providers/notification_badge_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('notification badge counts unread non-chat notifications', (
    tester,
  ) async {
    final provider = NotificationBadgeProvider(
      notificationApi: _FakeNotificationInboxClient(
        categories: [
          _category('support', unreadCount: 2),
          _category('activity', unreadCount: 4),
          _category('chat', unreadCount: 9),
        ],
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationBadgeProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotificationUnreadBadge(
                child: Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notification-unread-badge')),
      findsOneWidget,
    );
    expect(find.text('6'), findsOneWidget);
    expect(find.text('15'), findsNothing);
  });

  testWidgets('notification badge centers multi-digit labels in the bubble', (
    tester,
  ) async {
    final provider = NotificationBadgeProvider(
      notificationApi: _FakeNotificationInboxClient(
        categories: [_category('support', unreadCount: 41)],
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationBadgeProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 44,
                child: NotificationUnreadBadge(
                  child: Icon(Icons.notifications_none_rounded),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final badgeRect = tester.getRect(
      find.byKey(const ValueKey('notification-unread-badge')),
    );
    final labelRect = tester.getRect(find.text('41'));

    expect(
      (badgeRect.center.dx - labelRect.center.dx).abs(),
      lessThanOrEqualTo(0.5),
    );
    expect(
      (badgeRect.center.dy - labelRect.center.dy).abs(),
      lessThanOrEqualTo(0.5),
    );
  });
}

NotificationCategorySummary _category(
  String category, {
  required int unreadCount,
}) {
  return NotificationCategorySummary(
    category: category,
    unreadCount: unreadCount,
    totalCount: unreadCount,
    latest: UserNotification(
      id: '$category-latest',
      category: category,
      priority: 'normal',
      title: category,
      body: category,
      imageUrl: '',
      deepLink: '',
      data: category == 'chat'
          ? const {'event': 'chat_message', 'conversationId': 'chat-1'}
          : const {},
      createdAt: DateTime.utc(2026, 6, 27),
      readAt: null,
    ),
  );
}

class _FakeNotificationInboxClient implements NotificationInboxClient {
  const _FakeNotificationInboxClient({required this.categories});

  final List<NotificationCategorySummary> categories;

  @override
  Future<List<NotificationCategorySummary>> listNotificationCategories({
    int limit = 20,
  }) async {
    return categories;
  }

  @override
  Future<List<UserNotification>> listNotifications({
    required String category,
    int limit = 30,
    int offset = 0,
  }) async {
    return const [];
  }

  @override
  Future<NotificationReadResult> markNotificationCategoryRead({
    required String category,
  }) async {
    return const NotificationReadResult(updatedCount: 0);
  }

  @override
  Future<NotificationReadResult> markNotificationRead({
    required String notificationId,
  }) async {
    return const NotificationReadResult(updatedCount: 0);
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    return NotificationPreferences.defaults();
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferencesUpdate update,
  ) async {
    return NotificationPreferences.defaults();
  }
}
