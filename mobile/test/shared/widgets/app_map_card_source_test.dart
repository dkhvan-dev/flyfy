import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shared app map card renders MapLibre with app style and tap picking',
    () async {
      final source = await File(
        'lib/shared/widgets/app_map_card.dart',
      ).readAsString();

      expect(source, contains("package:maplibre/maplibre.dart"));
      expect(source, contains('MapLibreMap('));
      expect(source, contains('AppConfig.mapStyleUrl'));
      expect(source, contains('appMapGestureRecognizers()'));
      expect(source, contains('MapEventClick(point: final point)'));
      expect(source, contains('nativeMapEnabled'));
      expect(source, contains('_mapViewGeneration'));
      expect(source, contains("ValueKey('app-map-card-\$_mapViewGeneration')"));
      expect(source, contains('if (!mounted || !widget.nativeMapEnabled)'));
      expect(source, contains('void dispose()'));
      expect(source, contains('WidgetLayer('));
      expect(source, contains('AppMapAttribution('));
      expect(source, isNot(contains('SourceAttribution(')));
      expect(source, isNot(contains('Data from OpenStreetMap')));
      expect(source, isNot(contains('FlutterMap(')));
      expect(source, isNot(contains('TileLayer(')));
      expect(source, isNot(contains('tile.openstreetmap.org')));
    },
  );

  test('app map card handles style load through map events only', () async {
    final source = await File(
      'lib/shared/widgets/app_map_card.dart',
    ).readAsString();

    expect(source, contains('void _handleMapStyleLoaded()'));
    expect(source, contains('case MapEventStyleLoaded():'));
    expect(source, contains('_handleMapStyleLoaded();'));
    expect(source, contains('onEvent: _handleMapEvent'));
    expect(source, isNot(contains('onStyleLoaded:')));
  });
}
