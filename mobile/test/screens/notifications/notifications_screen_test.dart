import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/features/notifications/data/notification_api.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/notifications/notifications_screen.dart';
import 'package:provider/provider.dart';

void main() {
  test('notifications do not use profile timezone as user timezone', () async {
    final source = await File(
      'lib/screens/notifications/notifications_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('profile?.timezone')));
    expect(
      source,
      isNot(contains('userTimezoneId = context.read<SessionProvider>()')),
    );
  });

  test('notifications screens use the adaptive v2 design system', () async {
    final source = await File(
      'lib/screens/notifications/notifications_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('Theme('));
    expect(source, contains('data: AppDesignSystem.themeFor(context)'));
    expect(
      source,
      contains('final colors = AppDesignSystem.colorsFor(context)'),
    );
    expect(source, contains('backgroundColor: colors.background'));
    expect(source, contains('colors: colors.screenGradientColors'));
    expect(source, contains('AppPalette.primary'));
    expect(source, contains('AppPalette.secondary'));
    expect(source, contains('AppButtonStyles.icon(context.appColors)'));
    expect(source, contains('AppButtonStyles.primary(context.appColors)'));
    expect(
      source,
      isNot(
        matches(
          RegExp(
            r'AppPalette\.(warm|orange|amber|violet|pink|blue|green|teal|primary|white|black|background|surface|text)',
          ),
        ),
      ),
    );
  });

  test('notifications panels only use shadows in dark v2', () async {
    final source = await File(
      'lib/screens/notifications/notifications_screen.dart',
    ).readAsString();

    final panelStart = source.indexOf('class _InteractivePanel');
    final panelEnd = source.indexOf(
      'String _notificationCategoryUnreadBadgeLabel',
      panelStart,
    );

    expect(panelStart, isNonNegative);
    expect(panelEnd, greaterThan(panelStart));

    final panelSource = source.substring(panelStart, panelEnd);

    expect(panelSource, contains('final isDarkV2'));
    expect(panelSource, contains('Theme.of(context).brightness'));
    expect(panelSource, contains('Brightness.dark'));
    expect(panelSource, contains('boxShadow: isDarkV2'));
    expect(panelSource, contains('? ['));
    expect(panelSource, contains(': null'));
  });

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

  testWidgets('caps notification category unread badge at 99 plus', (
    tester,
  ) async {
    final api = _FakeNotificationInboxClient(
      categories: [
        NotificationCategorySummary(
          category: 'support',
          unreadCount: 150,
          totalCount: 150,
          latest: _supportReplyNotification(),
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

    expect(find.text('99+'), findsOneWidget);
    expect(find.textContaining('150'), findsNothing);
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

  testWidgets('shows support replies as a dedicated support category', (
    tester,
  ) async {
    final api = _FakeNotificationInboxClient(
      categories: [
        NotificationCategorySummary(
          category: 'support',
          unreadCount: 1,
          totalCount: 1,
          latest: _supportReplyNotification(),
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

    expect(find.text('Поддержка'), findsOneWidget);
    expect(find.text('Поддержка ответила'), findsOneWidget);
    expect(find.text('Поддержка ответила в вашем обращении.'), findsOneWidget);
    expect(find.text('Категория support'), findsNothing);
    expect(find.text('Support replied'), findsNothing);
    expect(find.text('Open support chat'), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-category-support')),
      findsOneWidget,
    );
  });

  testWidgets('hides chat message notifications from notification center', (
    tester,
  ) async {
    final api = _FakeNotificationInboxClient(
      categories: [
        NotificationCategorySummary(
          category: 'chat',
          unreadCount: 8,
          totalCount: 8,
          latest: _chatMessageNotification(),
        ),
        NotificationCategorySummary(
          category: 'support',
          unreadCount: 1,
          totalCount: 1,
          latest: _supportReplyNotification(),
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

    expect(
      find.byKey(const ValueKey('notification-category-chat')),
      findsNothing,
    );
    expect(find.text('Новое сообщение от devdone'), findsNothing);
    expect(find.text('Поддержка'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-category-support')),
      findsOneWidget,
    );
  });

  testWidgets('hides chat messages from notification category details', (
    tester,
  ) async {
    final api = _FakeNotificationInboxClient(
      notifications: [_chatMessageNotification()],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(),
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationCategoryScreen(
            category: 'chat',
            notificationApi: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notification-card-chat-message')),
      findsNothing,
    );
    expect(find.text('Новое сообщение от devdone'), findsNothing);
    expect(find.text('В этой категории пока нет уведомлений'), findsOneWidget);
  });

  testWidgets('marks notification read before opening deep link', (
    tester,
  ) async {
    final api = _FakeNotificationInboxClient(
      notifications: [_supportReplyNotification()],
    );
    final router = GoRouter(
      initialLocation: '/notifications/support',
      routes: [
        GoRoute(
          path: '/notifications/:category',
          builder: (_, state) => NotificationCategoryScreen(
            category: state.pathParameters['category'] ?? 'support',
            notificationApi: api,
          ),
        ),
        GoRoute(
          path: '/help/support',
          builder: (_, _) => const Scaffold(body: Text('Support destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(),
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('notification-card-support-replied')),
    );
    await tester.pumpAndSettle();

    expect(api.markedNotificationIds, ['support-replied']);
    expect(find.text('Support destination'), findsOneWidget);
  });

  testWidgets('marks unread notifications read when they become visible', (
    tester,
  ) async {
    final notifications = List<UserNotification>.generate(
      10,
      (index) => _longContentNotification(index),
    );
    final api = _FakeNotificationInboxClient(notifications: notifications);

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

    expect(api.markedNotificationIds, contains('content-visible-0'));
    expect(api.markedNotificationIds, isNot(contains('content-visible-9')));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(api.markedNotificationIds, contains('content-visible-9'));
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

  testWidgets('localizes support reply notification text', (tester) async {
    final api = _FakeNotificationInboxClient(
      notifications: [_supportReplyNotification()],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(),
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationCategoryScreen(
            category: 'support',
            notificationApi: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Поддержка ответила'), findsOneWidget);
    expect(find.text('Поддержка ответила в вашем обращении.'), findsOneWidget);
    expect(find.text('Support replied'), findsNothing);
    expect(find.text('Open support chat'), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-card-support-replied')),
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

UserNotification _supportReplyNotification() {
  return UserNotification(
    id: 'support-replied',
    category: 'support',
    priority: 'normal',
    title: 'Support replied',
    body: 'Open support chat',
    imageUrl: '',
    deepLink: '/help/support',
    data: const {'event': 'support_ticket_replied'},
    createdAt: DateTime.now().toUtc(),
    readAt: null,
  );
}

UserNotification _chatMessageNotification() {
  return UserNotification(
    id: 'chat-message',
    category: 'chat',
    priority: 'normal',
    title: 'New message from devdone',
    body: 'Open chat',
    imageUrl: '',
    deepLink: '/chats/conversation-1',
    data: const {
      'event': 'chat_message',
      'actorNickname': 'devdone',
      'conversationId': 'conversation-1',
    },
    createdAt: DateTime.now().toUtc(),
    readAt: null,
  );
}

UserNotification _longContentNotification(int index) {
  return UserNotification(
    id: 'content-visible-$index',
    category: 'content',
    priority: 'normal',
    title: 'Story like $index',
    body:
        'Long notification body $index. This keeps each notification card tall '
        'enough so only part of the list is visible at once in widget tests.',
    imageUrl: '',
    deepLink: '',
    data: {'type': 'story_like', 'actorNickname': 'devdone$index'},
    createdAt: DateTime.now().toUtc().subtract(Duration(minutes: index)),
    readAt: null,
  );
}

class _FakeNotificationInboxClient implements NotificationInboxClient {
  _FakeNotificationInboxClient({
    this.categories = const [],
    this.notifications = const [],
  });

  final List<NotificationCategorySummary> categories;
  final List<UserNotification> notifications;
  final List<String> markedNotificationIds = [];

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
  Future<NotificationReadResult> markNotificationRead({
    required String notificationId,
  }) async {
    markedNotificationIds.add(notificationId);
    return const NotificationReadResult(updatedCount: 1);
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
