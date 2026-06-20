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
