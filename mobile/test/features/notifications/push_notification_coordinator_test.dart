import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/notifications/presentation/push_notification_coordinator.dart';

void main() {
  group('PushNotificationDeepLinkResolver', () {
    const resolver = PushNotificationDeepLinkResolver();

    test('uses safe internal deep link route', () {
      expect(
        resolver.resolveRoute({'deepLink': '/activities/activity-1'}),
        '/activities/activity-1',
      );
    });

    test('converts app scheme links to internal routes', () {
      expect(
        resolver.resolveRoute({'deepLink': 'inflap://activities/activity-1'}),
        '/activities/activity-1',
      );
    });

    test('builds known routes from structured notification data', () {
      expect(
        resolver.resolveRoute({'activityId': 'activity-1'}),
        '/activities/activity-1',
      );
      expect(
        resolver.resolveRoute({'conversationId': 'conversation-1'}),
        '/chats/conversation-1',
      );
      expect(
        resolver.resolveRoute({'chatActivityId': 'activity-1'}),
        '/activities/activity-1/chat',
      );
    });

    test('builds checklist routes from structured notification data', () {
      final route = resolver.resolveRoute({
        'category': 'checklist',
        'checklistTripId': 'trip-bali-jan',
        'countryCode': 'ID',
        'cityName': 'Bali',
        'startAt': '2026-01-12T10:00:00Z',
        'endAt': '2026-01-19T10:00:00Z',
      });

      expect(route, startsWith('/travel-checklist?'));
      expect(route, contains('tripId=trip-bali-jan'));
      expect(route, contains('countryCode=ID'));
      expect(route, contains('cityName=Bali'));
    });

    test('rejects external or unsafe links', () {
      expect(
        resolver.resolveRoute({'deepLink': 'https://evil.test/phish'}),
        PushNotificationDeepLinkResolver.fallbackRoute,
      );
      expect(
        resolver.resolveRoute({'deepLink': 'javascript:alert(1)'}),
        PushNotificationDeepLinkResolver.fallbackRoute,
      );
    });
  });

  group('PushNotificationCoordinator', () {
    test('shows foreground notifications and routes local taps', () async {
      final source = _FakePushNotificationSource();
      final presenter = _FakePushNotificationPresenter();
      final routed = <String>[];
      var badgeRefreshes = 0;
      final coordinator = PushNotificationCoordinator(
        source: source,
        presenter: presenter,
        routeHandler: routed.add,
        onNotificationReceived: (envelope) {
          expect(envelope.id, 'message-1');
          badgeRefreshes++;
        },
      );

      await coordinator.start();
      source.foregroundController.add(
        const PushNotificationEnvelope(
          id: 'message-1',
          title: 'Trip update',
          body: 'New participant joined',
          data: {'activityId': 'activity-1'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(presenter.shown.single.title, 'Trip update');
      expect(presenter.shown.single.route, '/activities/activity-1');
      expect(badgeRefreshes, 1);

      presenter.tap(presenter.shown.single.route);
      expect(routed, ['/activities/activity-1']);

      await coordinator.dispose();
    });

    test('routes story notifications through the content channel', () async {
      final source = _FakePushNotificationSource();
      final presenter = _FakePushNotificationPresenter();
      final coordinator = PushNotificationCoordinator(
        source: source,
        presenter: presenter,
        routeHandler: (_) {},
      );

      await coordinator.start();
      source.foregroundController.add(
        const PushNotificationEnvelope(
          id: 'story-like-1',
          title: 'Новая реакция на историю',
          body: 'devdone нравится ваша история',
          data: {
            'category': 'content',
            'type': 'story_like',
            'storyId': 'story-1',
            'deepLink': '/posts/almaty-morning',
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(presenter.shown.single.channel, PushNotificationChannel.content);
      expect(presenter.shown.single.route, '/posts/almaty-morning');

      await coordinator.dispose();
    });

    test(
      'routes checklist notifications through the checklist channel',
      () async {
        final source = _FakePushNotificationSource();
        final presenter = _FakePushNotificationPresenter();
        final coordinator = PushNotificationCoordinator(
          source: source,
          presenter: presenter,
          routeHandler: (_) {},
        );

        await coordinator.start();
        source.foregroundController.add(
          const PushNotificationEnvelope(
            id: 'checklist-1',
            title: 'Проверьте документы',
            body: 'До поездки осталось 3 дня',
            data: {
              'category': 'checklist',
              'checklistTripId': 'trip-bali-jan',
              'countryCode': 'ID',
              'cityName': 'Bali',
              'startAt': '2026-01-12T10:00:00Z',
              'endAt': '2026-01-19T10:00:00Z',
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          presenter.shown.single.channel,
          PushNotificationChannel.checklists,
        );
        expect(presenter.shown.single.route, startsWith('/travel-checklist?'));

        await coordinator.dispose();
      },
    );

    test('routes notification opened from background', () async {
      final source = _FakePushNotificationSource();
      final presenter = _FakePushNotificationPresenter();
      final routed = <String>[];
      var badgeRefreshes = 0;
      final coordinator = PushNotificationCoordinator(
        source: source,
        presenter: presenter,
        routeHandler: routed.add,
        onNotificationReceived: (envelope) {
          expect(envelope.id, 'message-2');
          badgeRefreshes++;
        },
      );

      await coordinator.start();
      source.openedController.add(
        const PushNotificationEnvelope(
          id: 'message-2',
          title: 'Chat',
          body: 'New message',
          data: {'conversationId': 'conversation-1'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(routed, ['/chats/conversation-1']);
      expect(presenter.shown, isEmpty);
      expect(badgeRefreshes, 1);

      await coordinator.dispose();
    });
  });
}

class _FakePushNotificationSource implements PushNotificationSource {
  final foregroundController = StreamController<PushNotificationEnvelope>();
  final openedController = StreamController<PushNotificationEnvelope>();

  @override
  Stream<PushNotificationEnvelope> get foregroundMessages =>
      foregroundController.stream;

  @override
  Stream<PushNotificationEnvelope> get openedMessages =>
      openedController.stream;

  @override
  Future<PushNotificationEnvelope?> getInitialMessage() async => null;
}

class _FakePushNotificationPresenter implements PushNotificationPresenter {
  final shown = <PushNotificationDisplay>[];
  void Function(String route)? _onTap;

  @override
  Future<void> initialize({required void Function(String route) onTap}) async {
    _onTap = onTap;
  }

  @override
  Future<void> show(PushNotificationDisplay display) async {
    shown.add(display);
  }

  void tap(String route) {
    _onTap?.call(route);
  }
}
