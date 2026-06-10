import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/router/app_router.dart';

void main() {
  testWidgets('keyboard focus is cleared when navigator route changes', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(focusNode: focusNode)),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);

    KeyboardDismissRouteObserver().didPush(
      MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
      null,
    );
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  test('activity details route keeps android back-swipe wrapper', () async {
    final source = await File('lib/core/router/app_router.dart').readAsString();
    final detailsRouteIndex = source.indexOf("path: '/activities/:activityId'");

    expect(detailsRouteIndex, greaterThanOrEqualTo(0));
    expect(
      source.substring(detailsRouteIndex, detailsRouteIndex + 520),
      contains('return _withAndroidBackSwipe('),
    );
  });

  test(
    'activity edit route without navigation extra falls back to details',
    () async {
      final source = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final editRouteIndex = source.indexOf(
        "path: '/activities/:activityId/edit'",
      );
      final paymentRouteIndex = source.indexOf(
        "path: '/activities/:activityId/payment'",
      );

      expect(editRouteIndex, greaterThanOrEqualTo(0));
      expect(paymentRouteIndex, greaterThan(editRouteIndex));

      final routeSource = source.substring(editRouteIndex, paymentRouteIndex);
      expect(
        routeSource,
        contains(
          "final activityId = state.pathParameters['activityId'] ?? '';",
        ),
      );
      expect(routeSource, contains('if (activity == null)'));
      expect(routeSource, contains('ActivityDetailsScreen('));
      expect(routeSource, contains('activityId: activityId'));
      expect(routeSource, contains('initialActivity: activity'));
    },
  );

  test(
    'chat list route requires authentication before screen is built',
    () async {
      final source = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final publicRouteIndex = source.indexOf(
        'static bool _isPublicRoute(String location)',
      );

      expect(publicRouteIndex, greaterThanOrEqualTo(0));

      final publicRouteSource = source.substring(publicRouteIndex);
      expect(publicRouteSource, isNot(contains("location == '/chats'")));
    },
  );

  test(
    'foreign profile route is public but profile subflows stay protected',
    () async {
      final source = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final publicRouteIndex = source.indexOf(
        'static bool _isPublicRoute(String location)',
      );

      expect(publicRouteIndex, greaterThanOrEqualTo(0));

      final publicRouteSource = source.substring(publicRouteIndex);
      expect(
        publicRouteSource,
        contains(
          "location.startsWith('/users/') && location.endsWith('/profile')",
        ),
      );
      expect(
        publicRouteSource,
        isNot(contains("location.startsWith('/users/') {")),
      );
      expect(
        publicRouteSource,
        isNot(contains("location.endsWith('/followers')")),
      );
    },
  );

  test('services bottom tab opens the real services grid screen', () async {
    final source = await File('lib/core/router/app_router.dart').readAsString();
    final servicesRouteIndex = source.indexOf("path: '/services'");
    final currencyRouteIndex = source.indexOf(
      "path: '/currency-converter'",
      servicesRouteIndex,
    );

    expect(
      source,
      contains("import '../../screens/services/services_screen.dart';"),
    );
    expect(servicesRouteIndex, greaterThanOrEqualTo(0));
    expect(currencyRouteIndex, greaterThan(servicesRouteIndex));

    final routeSource = source.substring(
      servicesRouteIndex,
      currencyRouteIndex,
    );
    expect(routeSource, contains('const ServicesScreen()'));
    expect(routeSource, isNot(contains('FeatureStubScreen')));
  });
}
