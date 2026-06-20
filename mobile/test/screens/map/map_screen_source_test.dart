import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map screen uses a configurable MapLibre vector style', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();
    final configSource = await File(
      'lib/core/config/app_config.dart',
    ).readAsString();
    final pubspecSource = await File('pubspec.yaml').readAsString();

    expect(pubspecSource, contains('maplibre:'));
    expect(mapSource, contains("import 'package:maplibre/maplibre.dart'"));
    expect(mapSource, contains('class MapActivityTarget'));
    expect(mapSource, contains('class MapActivityCollection'));
    expect(mapSource, contains('MapLibreMap('));
    expect(mapSource, contains('AppConfig.mapStyleUrl'));
    expect(mapSource, contains('appMapGestureRecognizers()'));
    expect(mapSource, contains('AppMapAttribution('));
    expect(mapSource, isNot(contains('SourceAttribution(')));
    expect(mapSource, isNot(contains('Data from OpenStreetMap')));
    expect(mapSource, contains('_bootstrapActivityMarkers('));
    expect(mapSource, contains('activityViewDetails'));
    expect(mapSource, contains('await context.push(route);'));
    expect(configSource, contains('INFLAP_MAP_STYLE_URL'));
    expect(configSource, contains('tiles.openfreemap.org'));
    expect(mapSource, isNot(contains('tile.openstreetmap.org')));
    expect(mapSource, isNot(contains('TileLayer(')));
  });

  test('activity map mode is fast responsive and gesture stable', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();
    final deviceContextSource = await File(
      'lib/core/device/device_context_service.dart',
    ).readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();

    expect(mapSource, contains('_bootstrapActivityMarkersSync('));
    expect(mapSource, contains('_loadActivityUserLocation('));
    expect(mapSource, contains('requestPermission: true'));
    expect(mapSource, contains('moveCamera: true'));
    expect(mapSource, contains('_selectedPlace = null;'));
    expect(mapSource, contains('detectCoordinates('));
    expect(deviceContextSource, contains('class DeviceCoordinates'));
    expect(
      deviceContextSource,
      contains('Future<DeviceCoordinates?> detectCoordinates'),
    );
    expect(mapSource, contains('mapDistancePending'));
    expect(mapSource, contains('_hideInteractiveMarkersDuringCameraMove'));
    expect(mapSource, contains('CircleLayer('));
    expect(mapSource, contains('_buildStableAnnotationLayers()'));
    expect(
      mapSource,
      contains('if (!_hideInteractiveMarkersDuringCameraMove)'),
    );
    expect(mapSource, contains('FlexFit.tight'));
    expect(mapSource, contains('maxHeight: bottomPanelMaxHeight'));
    expect(ruArb, contains('"mapDistancePending": "Определяем расстояние"'));
  });

  test('activity details navigation suspends native iOS map view', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('bool _mapSuspendedForNavigation = false;'));
    expect(mapSource, contains('int _mapViewGeneration = 0;'));
    expect(mapSource, contains('Future<void> _openPlaceDetails'));
    expect(mapSource, contains('_suspendNativeMapForRoute();'));
    expect(mapSource, contains('await WidgetsBinding.instance.endOfFrame;'));
    expect(mapSource, contains('_resumeNativeMapAfterRoute();'));
    expect(mapSource, contains('key: ValueKey('));
    expect(mapSource, contains("'maplibre-\$_mapViewGeneration'"));
    expect(mapSource, contains('child: _mapSuspendedForNavigation'));
    expect(mapSource, contains('class _MapNativeSuspendedPlaceholder'));
    expect(mapSource, contains('_mapSuspendedForNavigation || !_mapReady'));
  });

  test('activity map selected card keeps metadata responsive', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();
    final activitiesSource = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    expect(mapSource, contains('required this.startLabel'));
    expect(mapSource, contains('required this.priceLabel'));
    expect(mapSource, contains('place.startLabel'));
    expect(mapSource, contains('place.priceLabel'));
    expect(mapSource, contains('_SelectedPlaceMeta('));
    expect(mapSource, contains('place.categoryLabel'));
    expect(
      mapSource,
      contains('SizedBox(width: double.infinity, child: button)'),
    );
    expect(mapSource, contains('constraints.maxHeight >='));
    expect(mapSource, contains("place.categoryValue == 'activity'"));
    expect(activitiesSource, contains('startLabel: dateLabel'));
    expect(activitiesSource, contains('priceLabel: priceLabel'));
  });

  test('target map keeps place marker and also loads user location', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('Future<void> _loadTargetUserLocation('));
    expect(
      mapSource,
      contains('_loadTargetUserLocation(requestPermission: true)'),
    );
    expect(mapSource, contains('_userLocation = userPoint;'));
    expect(mapSource, contains('_targetPlace = targetPlace;'));
    expect(mapSource, contains('_selectedPlace = targetPlace;'));
  });

  test('nearby places map is not capped at forty POI', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('_nearbyPlacesPrimaryLimit'));
    expect(mapSource, contains('_nearbyPlacesFallbackLimit'));
    expect(mapSource, contains('resultLimit: _nearbyPlacesPrimaryLimit'));
    expect(mapSource, contains('resultLimit: _nearbyPlacesFallbackLimit'));
    expect(mapSource, isNot(contains('resultLimit: 40')));
    expect(mapSource, isNot(contains('resultLimit: 28')));
  });
}
