import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/notifications/data/notification_api.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/notifications/notifications_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('localizes latest category preview text', (tester) async {
    final latest = _storyLikeNotification();
    final api = _FakeNotificationInboxClient(
      categories: [
        NotificationCategorySummary(
          category: 'story',
          unreadCount: 1,
          totalCount: 1,
          latest: latest,
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(),
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationsOverviewScreen(notificationApi: api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('devdone нравится ваша история'), findsOneWidget);
    expect(find.text('devdone likes your story'), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-category-story')),
      findsOneWidget,
    );
  });

  testWidgets('localizes activity and excursion cancellation previews', (
    tester,
  ) async {
    final api = _FakeNotificationInboxClient(
      categories: [
        NotificationCategorySummary(
          category: 'activity',
          unreadCount: 20,
          totalCount: 20,
          latest: _activityCancelledNotification(),
        ),
        NotificationCategorySummary(
          category: 'excursion',
          unreadCount: 7,
          totalCount: 7,
          latest: _excursionBookingCancelledNotification(),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(),
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationsOverviewScreen(notificationApi: api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Активность отменена'), findsOneWidget);
    expect(find.text('Активность «test» отменена.'), findsOneWidget);
    expect(find.text('Бронь экскурсии отменена'), findsOneWidget);
    expect(find.text('Путешественник отменил эту экскурсию.'), findsOneWidget);
    expect(find.text('Activity cancelled'), findsNothing);
    expect(find.text('test was cancelled.'), findsNothing);
    expect(find.text('Excursion booking cancelled'), findsNothing);
    expect(find.text('A traveler cancelled this excursion.'), findsNothing);
  });

  testWidgets('localizes templated notification text', (tester) async {
    final api = _FakeNotificationInboxClient(
      notifications: [_storyLikeNotification()],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(),
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationCategoryScreen(
            category: 'content',
            notificationApi: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('devdone нравится ваша история'), findsOneWidget);
    expect(find.text('devdone likes your story'), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-card-notification-1')),
      findsOneWidget,
    );
  });
}

UserNotification _activityCancelledNotification() {
  return UserNotification(
    id: 'activity-cancelled',
    category: 'activity',
    priority: 'high',
    title: 'Activity cancelled',
    body: 'test was cancelled.',
    imageUrl: '',
    deepLink: '/activities/activity-1',
    data: const {'activityEvent': 'activity_cancelled'},
    createdAt: DateTime.now().toUtc(),
    readAt: null,
  );
}

UserNotification _excursionBookingCancelledNotification() {
  return UserNotification(
    id: 'excursion-booking-cancelled',
    category: 'excursion',
    priority: 'high',
    title: 'Excursion booking cancelled',
    body: 'A traveler cancelled this excursion.',
    imageUrl: '',
    deepLink: '/me/excursions',
    data: const {'excursionEvent': 'booking_cancelled_by_tourist'},
    createdAt: DateTime.now().toUtc(),
    readAt: null,
  );
}

UserNotification _storyLikeNotification() {
  return UserNotification(
    id: 'notification-1',
    category: 'content',
    priority: 'normal',
    title: 'devdone likes your story',
    body: 'Open story',
    imageUrl: '',
    deepLink: '',
    data: const {'type': 'story_like', 'actorNickname': 'devdone'},
    createdAt: DateTime.now().toUtc(),
    readAt: null,
  );
}

class _FakeNotificationInboxClient implements NotificationInboxClient {
  const _FakeNotificationInboxClient({
    this.categories = const [],
    this.notifications = const [],
  });

  final List<NotificationCategorySummary> categories;
  final List<UserNotification> notifications;

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
    return notifications;
  }

  @override
  Future<NotificationReadResult> markNotificationCategoryRead({
    required String category,
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
