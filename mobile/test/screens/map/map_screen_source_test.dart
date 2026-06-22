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

  test(
    'route preview uses dedicated map args without overloading target',
    () async {
      final mapSource = await File(
        'lib/screens/map/map_screen.dart',
      ).readAsString();
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();

      expect(mapSource, contains('class MapRoutePreview'));
      expect(mapSource, contains('final MapRoutePreview? routePreview;'));
      expect(mapSource, contains('final RoutePointVm? origin;'));
      expect(mapSource, contains('RouteSummaryCard('));
      expect(mapSource, contains('PolylineLayer('));
      expect(mapSource, contains('_routePolylineFeature('));
      expect(mapSource, contains('LineString.from('));
      expect(mapSource, contains('route.displayPoints'));
      expect(mapSource, contains('RouteModeSelector('));
      expect(mapSource, contains('Future<void> _switchRouteProfile('));
      expect(mapSource, contains('context.read<RoutingProvider>()'));
      expect(mapSource, contains('profile: profile'));
      expect(routerSource, contains('state.extra is MapRoutePreview'));
      expect(routerSource, contains('routePreview: routePreview'));
    },
  );

  test('route preview keeps map focused on route only', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('bool get _isRoutePreviewMode'));
    expect(mapSource, contains('bool get _hidesNearbyPlaces'));
    expect(mapSource, contains('Future<void> _bootstrapRoutePreview('));
    expect(mapSource, contains('_hidesNearbyPlaces || _showsActivityMarkers'));
    expect(mapSource, contains('if (_isRoutePreviewMode) return;'));
    expect(mapSource, contains('if (!_hidesNearbyPlaces &&'));
    expect(mapSource, contains('_places.isNotEmpty'));
    expect(mapSource, contains('if (!_hidesNearbyPlaces)'));
  });

  test('route preview fits the whole route after map style loads', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('void _focusRoutePreviewCamera('));
    expect(mapSource, contains('LngLatBounds? _routePreviewBounds('));
    expect(mapSource, contains('LngLatBounds.fromPoints('));
    expect(mapSource, contains('mapController.fitBounds('));
    expect(mapSource, contains('padding: EdgeInsets.all('));
    expect(mapSource, contains('_focusRoutePreviewCamera(preview);'));
    expect(
      mapSource,
      contains('_focusRoutePreviewCamera(preview, animate: true);'),
    );
    expect(mapSource, contains('final styleRoutePreview ='));
    expect(mapSource, contains('styleRoutePreview'));
    expect(mapSource, isNot(contains('zoom: _routePreviewZoom(preview)')));
  });

  test('route preview camera fit is retried after native map layout', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('static const double _routePreviewInitialZoom'));
    expect(mapSource, contains('_initialMapZoom'));
    expect(mapSource, contains('initZoom: _initialMapZoom,'));
    expect(mapSource, contains('void _scheduleRoutePreviewCameraFit('));
    expect(mapSource, contains('WidgetsBinding.instance.addPostFrameCallback'));
    expect(mapSource, contains('_routePreviewCameraFitRetry'));
    expect(mapSource, contains('_routePreviewCameraFitLateRetry'));
    expect(mapSource, contains('const Duration(milliseconds: 180)'));
    expect(mapSource, contains('const Duration(milliseconds: 650)'));
    expect(mapSource, contains('_cancelRoutePreviewCameraFitRetry();'));
    expect(mapSource, contains('final styleRoutePreview ='));
    expect(
      mapSource,
      matches(
        RegExp(
          r'if \(styleRoutePreview != null\) \{\s+'
          r'_scheduleRoutePreviewCameraFit\(\s+styleRoutePreview,',
        ),
      ),
    );
  });

  test(
    'route preview camera bounds always include origin and destination',
    () async {
      final mapSource = await File(
        'lib/screens/map/map_screen.dart',
      ).readAsString();

      expect(mapSource, contains('void _addRoutePreviewBoundPoint('));
      expect(
        mapSource,
        contains('for (final stop in _routePreviewStops(preview))'),
      );
      expect(
        mapSource,
        contains('_addRoutePreviewBoundPoint(points, stop.point);'),
      );
      expect(
        mapSource,
        isNot(
          contains(
            'if (points.length < 2) {\n'
            '      points\n'
            '        ..clear()',
          ),
        ),
      );
    },
  );

  test('route preview keeps current user location visible', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('Future<void> _loadRoutePreviewUserLocation('));
    expect(
      mapSource,
      contains('_loadRoutePreviewUserLocation(requestPermission: true)'),
    );
    expect(mapSource, contains('_userLocation = userPoint;'));
    expect(mapSource, contains("_pointFeature('user-location', userLocation)"));
    expect(
      mapSource,
      isNot(contains('if (userLocation != null && !_isRoutePreviewMode)')),
    );
    expect(
      mapSource,
      isNot(
        contains(
          '_userLocation != null &&\n                                                          !_isRoutePreviewMode',
        ),
      ),
    );
  });

  test(
    'route preview info panel is below the map and has no external maps CTA',
    () async {
      final mapSource = await File(
        'lib/screens/map/map_screen.dart',
      ).readAsString();

      expect(
        mapSource,
        isNot(contains("import 'package:url_launcher/url_launcher.dart';")),
      );
      expect(
        mapSource,
        isNot(contains('Future<void> _openRoutePreviewExternally(')),
      );
      expect(mapSource, isNot(contains('LaunchMode.externalApplication')));
      expect(mapSource, isNot(contains('onOpenExternalMap:')));
      expect(
        mapSource,
        contains('routePreview == null || _isRouteBuilderMode'),
      );
      expect(mapSource, contains('routeBuilderPanel != null'));
      expect(mapSource, contains('routePreviewPanel,'));
      expect(
        mapSource,
        isNot(
          contains(
            'bottom: _mapScaled(\n'
            '                                          context,\n'
            '                                          14,',
          ),
        ),
      );
    },
  );

  test('route preview profile switching preserves multi stop routes', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(mapSource, contains('this.routePoints = const [],'));
    expect(mapSource, contains('final List<RoutePointVm> routePoints;'));
    expect(
      mapSource,
      contains('final routePoints = preview.routePoints.isNotEmpty'),
    );
    expect(mapSource, contains('points: routePoints'));
    expect(mapSource, contains('routePoints: routePoints,'));
  });

  test('route preview save CTA is gated behind custom routes flag', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();

    expect(
      mapSource,
      contains("features/user_routes/user_route_feature_flags.dart"),
    );
    expect(mapSource, contains('showSaveRoute:'));
    expect(mapSource, contains('UserRouteFeatureFlags.customRoutesEnabled'));
    expect(mapSource, contains('final bool showSaveRoute;'));
    expect(mapSource, contains('if (showSaveRoute)'));
  });

  test('map save route buttons use primary text color', () async {
    final mapSource = await File(
      'lib/screens/map/map_screen.dart',
    ).readAsString();
    final saveButtonSections = <String>[];
    var searchOffset = 0;
    while (true) {
      final labelIndex = mapSource.indexOf(
        'l10n.userRoutesSaveRoute',
        searchOffset,
      );
      if (labelIndex < 0) {
        break;
      }
      final buttonStart = mapSource.lastIndexOf(
        'FilledButton.icon(',
        labelIndex,
      );
      expect(buttonStart, isNonNegative);
      saveButtonSections.add(mapSource.substring(buttonStart, labelIndex));
      searchOffset = labelIndex + 1;
    }

    expect(saveButtonSections.length, greaterThanOrEqualTo(1));
    for (final section in saveButtonSections) {
      expect(section, contains('foregroundColor: AppColors.textPrimary'));
      expect(
        section,
        isNot(contains('foregroundColor: const Color(0xFF241100)')),
      );
    }
  });

  test(
    'custom route builder is gated while point to destination routes remain',
    () async {
      final mapSource = await File(
        'lib/screens/map/map_screen.dart',
      ).readAsString();
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final userRoutesSource = await File(
        'lib/features/user_routes/presentation/user_routes_screen.dart',
      ).readAsString();

      expect(mapSource, contains('routeBuilderEnabled'));
      expect(
        mapSource,
        contains(
          'bool get _isRouteBuilderMode =>\n'
          '      UserRouteFeatureFlags.customRoutesEnabled && widget.routeBuilderEnabled;',
        ),
      );
      expect(mapSource, contains('_routeBuilderPoints'));
      expect(mapSource, contains('_handleRouteBuilderMapTap('));
      expect(mapSource, contains('MapEventClick(point: final point'));
      expect(mapSource, contains('_buildCustomRoutePreview('));
      expect(mapSource, contains('context.read<RoutingProvider>()'));
      expect(mapSource, contains('RouteRequestVm('));
      expect(mapSource, contains('class _RouteBuilderPanel'));
      expect(mapSource, contains('mapRouteBuilderBuildRoute'));
      expect(mapSource, contains('mapRouteBuilderClear'));
      expect(
        routerSource,
        contains('UserRouteFeatureFlags.customRoutesEnabled &&'),
      );
      expect(routerSource, contains("mode == 'route-builder'"));
      expect(
        routerSource,
        contains('routeBuilderEnabled: routeBuilderEnabled'),
      );
      expect(
        userRoutesSource,
        contains('if (UserRouteFeatureFlags.customRoutesEnabled)'),
      );
    },
  );

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
