import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/notifications/presentation/push_notification_banner.dart';
import 'package:inflap/features/notifications/presentation/push_notification_coordinator.dart';

void main() {
  testWidgets('shows an in-app notification banner and routes taps', (
    tester,
  ) async {
    final controller = PushNotificationBannerController();
    final presenter = InAppPushNotificationPresenter(controller: controller);
    final routed = <String>[];

    await presenter.initialize(onTap: routed.add);
    await tester.pumpWidget(
      MaterialApp(
        home: PushNotificationBannerHost(
          controller: controller,
          visibleDuration: const Duration(seconds: 30),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    await presenter.show(
      const PushNotificationDisplay(
        id: 'activity-1',
        title: 'Trip update',
        body: 'New participant joined your activity',
        route: '/activities/activity-1',
        channel: PushNotificationChannel.activity,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Trip update'), findsOneWidget);
    expect(find.text('New participant joined your activity'), findsOneWidget);
    expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);

    await tester.tap(find.text('Trip update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(routed, ['/activities/activity-1']);
    expect(find.text('Trip update'), findsNothing);

    await controller.dispose();
  });

  testWidgets('dismisses the active banner without routing', (tester) async {
    final controller = PushNotificationBannerController();
    final presenter = InAppPushNotificationPresenter(controller: controller);
    final routed = <String>[];

    await presenter.initialize(onTap: routed.add);
    await tester.pumpWidget(
      MaterialApp(
        home: PushNotificationBannerHost(
          controller: controller,
          visibleDuration: const Duration(seconds: 30),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    await presenter.show(
      const PushNotificationDisplay(
        id: 'message-1',
        title: 'New message',
        body: 'A guide sent you a reply',
        route: '/chats/conversation-1',
        channel: PushNotificationChannel.messages,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New message'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(routed, isEmpty);
    expect(find.text('New message'), findsNothing);

    await controller.dispose();
  });

  testWidgets('keeps long content responsive on compact screens', (
    tester,
  ) async {
    final previousOnError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];
    FlutterError.onError = flutterErrors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    tester.view
      ..physicalSize = const Size(280, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PushNotificationBannerController();
    final presenter = InAppPushNotificationPresenter(controller: controller);

    await presenter.initialize(onTap: (_) {});
    await tester.pumpWidget(
      MaterialApp(
        home: PushNotificationBannerHost(
          controller: controller,
          visibleDuration: const Duration(seconds: 30),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    await presenter.show(
      const PushNotificationDisplay(
        id: 'compact-activity-1',
        title:
            'Very long activity notification title that should wrap without horizontal overflow',
        body:
            'A very long notification body with localized text and route details should stay inside the in-app banner on compact Android devices.',
        route: '/activities/compact-activity-1',
        channel: PushNotificationChannel.activity,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(flutterErrors, isEmpty);
    expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);

    await controller.dispose();
  });

  testWidgets('does not require a Flutter Overlay ancestor', (tester) async {
    final previousOnError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];
    FlutterError.onError = flutterErrors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    final controller = PushNotificationBannerController();
    final presenter = InAppPushNotificationPresenter(controller: controller);

    await presenter.initialize(onTap: (_) {});
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PushNotificationBannerHost(
            controller: controller,
            visibleDuration: const Duration(seconds: 30),
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );

    await presenter.show(
      const PushNotificationDisplay(
        id: 'overlay-free-1',
        title: 'Inflap test',
        body: 'Banner renders above the app builder without Overlay lookup.',
        route: '/notifications',
        channel: PushNotificationChannel.system,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(flutterErrors, isEmpty);

    await controller.dispose();
  });
}
