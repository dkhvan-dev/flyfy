import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'app map attribution brands the map while preserving OSM credit',
    () async {
      final source = await File(
        'lib/shared/widgets/app_map_attribution.dart',
      ).readAsString();

      expect(source, contains('Inflap Map'));
      expect(source, contains('OpenMapTiles'));
      expect(source, contains('OpenStreetMap'));
      expect(source, contains('AppMapLinks.host'));
      expect(source, contains('launchUrl('));
      expect(source, isNot(contains('Data from OpenStreetMap')));
    },
  );
}
