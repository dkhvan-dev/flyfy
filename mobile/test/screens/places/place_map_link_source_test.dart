import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'place details opens internal app map links instead of OSM source URLs',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      expect(source, contains("import '../../shared/map/app_map_links.dart';"));
      expect(source, contains('AppMapLinks.buildUrl('));
      expect(
        source,
        isNot(contains('final sourceUrl = place.locationSourceUrl.trim();')),
      );
      expect(source, isNot(contains('sourceUrl.isEmpty ? null : sourceUrl')));
    },
  );

  test(
    'place details builds route preview for authenticated map opens',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/routing_provider.dart';"),
      );
      expect(source, contains("import '../../providers/auth_provider.dart';"));
      expect(
        source,
        contains("import '../../core/device/device_context_service.dart';"),
      );
      expect(source, contains('bool _isBuildingRoute = false;'));
      expect(source, contains('Future<void> _openRouteToPlace('));
      expect(source, contains('context.read<RoutingProvider>()'));
      expect(source, contains('RouteRequestVm('));
      expect(source, contains('RouteProfile.touristWalk'));
      expect(source, contains('MapRoutePreview('));
      expect(source, contains('final origin = RoutePointVm('));
      expect(source, contains('origin: origin'));
      expect(source, contains('extra: routePreview'));
    },
  );

  test('map route accepts internal coordinate links', () async {
    final source = await File('lib/core/router/app_router.dart').readAsString();

    expect(source, contains('_mapTargetFromQuery('));
    expect(source, contains("state.uri.queryParameters['lat']"));
    expect(source, contains("state.uri.queryParameters['lon']"));
    expect(source, contains('MapTarget('));
  });

  test(
    'place source URL migration rewrites OSM links to app map links',
    () async {
      final source = await File(
        '../backend/services/place-service/migrations/084_update_place_map_links.up.sql',
      ).readAsString();

      expect(source, contains('https://inflap.app/map?lat='));
      expect(
        source,
        contains("location_source_url LIKE 'https://www.openstreetmap.org/%'"),
      );
      expect(
        source,
        isNot(
          contains('SET location_source_url = \'https://www.openstreetmap.org'),
        ),
      );
    },
  );
}
