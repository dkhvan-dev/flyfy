import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router gates user routes list and detail pages', () async {
    final source = await File('lib/core/router/app_router.dart').readAsString();

    expect(
      source,
      contains("features/user_routes/user_route_feature_flags.dart"),
    );
    expect(source, contains("path: '/user-routes'"));
    expect(source, contains("path: '/user-routes/:routeId'"));
    expect(source, contains('UserRoutesScreen('));
    expect(source, contains('UserRouteDetailsScreen('));
    expect(source, contains('UserRouteFeatureFlags.customRoutesEnabled'));
    expect(
      source,
      contains("UserRouteFeatureFlags.customRoutesEnabled ? null : '/'"),
    );
    expect(source, contains('UserRouteFeatureFlags.customRoutesEnabled &&'));
    expect(source, contains("mode == 'route-builder'"));
  });

  test(
    'own profile hides user routes when custom routes are disabled',
    () async {
      final source = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("features/user_routes/user_route_feature_flags.dart"),
      );
      expect(
        source,
        contains('if (UserRouteFeatureFlags.customRoutesEnabled)'),
      );
      expect(source, contains("context.push('/user-routes')"));
      expect(source, contains('profileUserRoutesTitle'));
      expect(source, contains('profileUserRoutesSubtitle'));
    },
  );
}
