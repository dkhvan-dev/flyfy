import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart' hide LengthUnit;
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/device/device_context_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/routing/models/routing_models.dart';
import '../../features/routing/widgets/route_mode_selector.dart';
import '../../features/routing/widgets/route_summary_card.dart';
import '../../features/user_routes/models/user_route_models.dart';
import '../../features/user_routes/user_route_feature_flags.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/routing_provider.dart';
import '../../providers/user_routes_provider.dart';
import '../../shared/map/app_map_gesture_recognizers.dart';
import '../../shared/map/app_map_links.dart';
import '../../shared/widgets/app_map_attribution.dart';

class MapTarget {
  const MapTarget({
    required this.title,
    required this.latitude,
    required this.longitude,
    this.subtitle,
    this.sourceUrl,
  });

  final String title;
  final String? subtitle;
  final double latitude;
  final double longitude;
  final String? sourceUrl;

  LatLng get point => LatLng(latitude, longitude);
}

class MapActivityTarget {
  const MapActivityTarget({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.detailRoute,
    required this.categoryLabel,
    required this.metaLabel,
    required this.startLabel,
    required this.priceLabel,
    this.avatarLabel,
    this.icon = Icons.event_available_rounded,
    this.accentColor = const Color(0xFFFFB44D),
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final String detailRoute;
  final String categoryLabel;
  final String metaLabel;
  final String startLabel;
  final String priceLabel;
  final String? avatarLabel;
  final IconData icon;
  final Color accentColor;

  LatLng get point => LatLng(latitude, longitude);
}

class MapActivityCollection {
  const MapActivityCollection({required this.title, required this.activities});

  final String title;
  final List<MapActivityTarget> activities;
}

class MapRoutePreview {
  const MapRoutePreview({
    required this.route,
    this.origin,
    this.destination,
    this.routePoints = const [],
    this.enabledProfiles = const [
      RouteProfile.touristWalk,
      RouteProfile.bikeCity,
      RouteProfile.carStandard,
    ],
  });

  final RouteResponseVm route;
  final RoutePointVm? origin;
  final MapTarget? destination;
  final List<RoutePointVm> routePoints;
  final List<RouteProfile> enabledProfiles;
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.initialTarget,
    this.activityCollection,
    this.routePreview,
    this.routeBuilderEnabled = false,
  });

  final MapTarget? initialTarget;
  final MapActivityCollection? activityCollection;
  final MapRoutePreview? routePreview;
  final bool routeBuilderEnabled;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _fallbackCenter = LatLng(43.238949, 76.889709);
  static const double _defaultZoom = 14.6;
  static const double _routePreviewInitialZoom = 10.4;
  static const int _searchRadiusMeters = 1800;

  MapController? _mapController;
  final DeviceContextService _deviceContextService =
      const DeviceContextService();
  final _NearbyPlacesApi _placesApi = _NearbyPlacesApi();
  final Distance _distance = const Distance();

  Timer? _reloadDebounce;
  Timer? _placesRetryDebounce;
  Timer? _routePreviewCameraFitRetry;
  Timer? _routePreviewCameraFitLateRetry;

  bool _bootstrapping = true;
  bool _loadingPlaces = false;
  bool _locatingUser = false;
  bool _mapReady = false;
  bool _mapSuspendedForNavigation = false;
  bool _cameraChangeStartedByUser = false;
  bool _hideInteractiveMarkersDuringCameraMove = false;
  String? _locationIssueCode;
  String? _placesErrorMessage;
  String? _locationLabel;
  String? _routePreviewError;
  String? _savedRoutePreviewSignature;
  LatLng _mapCenter = _fallbackCenter;
  LatLng? _userLocation;
  MapRoutePreview? _routePreview;
  _LocalPlace? _targetPlace;
  List<_LocalPlace> _places = const [];
  _LocalPlace? _selectedPlace;
  bool _switchingRouteProfile = false;
  bool _savingRoutePreview = false;
  bool _buildingCustomRoute = false;
  List<RoutePointVm> _routeBuilderPoints = const [];
  String? _routeBuilderError;
  int _autoPlacesRetryCount = 0;
  int _mapViewGeneration = 0;

  @override
  void initState() {
    super.initState();
    _routePreview = widget.routePreview;
    final activityCollection = widget.activityCollection;
    if (activityCollection != null &&
        activityCollection.activities.isNotEmpty) {
      _bootstrapActivityMarkers(activityCollection);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          _loadActivityUserLocation(requestPermission: true, moveCamera: true),
        );
      });
      return;
    }

    final routePreview = _routePreview;
    if (routePreview != null) {
      unawaited(_bootstrapRoutePreview(routePreview));
      return;
    }

    if (widget.routeBuilderEnabled) {
      unawaited(_bootstrapRouteBuilder());
      return;
    }

    final target = widget.initialTarget;
    if (target != null) {
      unawaited(_bootstrapTarget(target));
    } else {
      unawaited(_bootstrap());
    }
  }

  bool get _showsActivityMarkers =>
      widget.activityCollection?.activities.isNotEmpty == true;

  bool get _isRoutePreviewMode => _routePreview != null;

  bool get _isRouteBuilderMode =>
      UserRouteFeatureFlags.customRoutesEnabled && widget.routeBuilderEnabled;

  bool get _hidesNearbyPlaces => _isRoutePreviewMode || _isRouteBuilderMode;

  double get _initialMapZoom =>
      _isRoutePreviewMode ? _routePreviewInitialZoom : _defaultZoom;

  bool get _routePreviewSaved {
    final preview = _routePreview;
    final savedSignature = _savedRoutePreviewSignature;
    return preview != null &&
        savedSignature != null &&
        savedSignature == _routePreviewSignature(preview);
  }

  void _bootstrapActivityMarkers(MapActivityCollection collection) {
    _bootstrapActivityMarkersSync(collection);
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _placesRetryDebounce?.cancel();
    _cancelRoutePreviewCameraFitRetry();
    _mapReady = false;
    _mapController = null;
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _autoPlacesRetryCount = 0;
    _placesRetryDebounce?.cancel();
    setState(() {
      _bootstrapping = true;
      _placesErrorMessage = null;
    });

    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion();
      if (suggestion == null) {
        throw Exception('location_unavailable');
      }
      if (!mounted) return;

      final center = LatLng(suggestion.latitude, suggestion.longitude);
      setState(() {
        _mapCenter = center;
        _userLocation = center;
        _locationLabel = _buildLocationLabel(suggestion);
        _locationIssueCode = null;
        _bootstrapping = false;
      });

      _moveMap(center);
      await _loadPlaces(center, selectFirst: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mapCenter = _fallbackCenter;
        _userLocation = null;
        _locationLabel = null;
        _locationIssueCode = error.toString();
        _bootstrapping = false;
      });
      await _loadPlaces(_fallbackCenter, selectFirst: true);
    }
  }

  Future<void> _bootstrapRouteBuilder() async {
    _autoPlacesRetryCount = 0;
    _placesRetryDebounce?.cancel();
    setState(() {
      _bootstrapping = true;
      _placesErrorMessage = null;
      _selectedPlace = null;
      _targetPlace = null;
      _places = const [];
    });

    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion();
      if (suggestion == null) {
        throw Exception('location_unavailable');
      }
      if (!mounted) return;

      final center = LatLng(suggestion.latitude, suggestion.longitude);
      setState(() {
        _mapCenter = center;
        _userLocation = center;
        _locationLabel = _buildLocationLabel(suggestion);
        _locationIssueCode = null;
        _bootstrapping = false;
      });
      _moveMap(center);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mapCenter = _fallbackCenter;
        _userLocation = null;
        _locationLabel = null;
        _locationIssueCode = error.toString();
        _bootstrapping = false;
      });
      _moveMap(_fallbackCenter);
    }
  }

  Future<void> _bootstrapTarget(MapTarget target) async {
    _autoPlacesRetryCount = 0;
    _placesRetryDebounce?.cancel();

    final targetPlace = _LocalPlace(
      id: 'target:${target.latitude}:${target.longitude}',
      title: target.title,
      categoryValue: 'place',
      categoryLabel: target.subtitle?.trim().isNotEmpty == true
          ? target.subtitle!.trim()
          : target.title,
      point: target.point,
      distanceMeters: 0,
      sourceUrl: target.sourceUrl,
    );

    setState(() {
      _mapCenter = target.point;
      _userLocation = null;
      _targetPlace = targetPlace;
      _selectedPlace = targetPlace;
      _locationLabel = target.subtitle?.trim().isNotEmpty == true
          ? target.subtitle!.trim()
          : target.title;
      _locationIssueCode = null;
      _placesErrorMessage = null;
      _bootstrapping = false;
    });

    _moveMap(target.point);
    unawaited(_loadTargetUserLocation(requestPermission: true));
    await _loadPlaces(target.point);
  }

  Future<void> _bootstrapRoutePreview(MapRoutePreview preview) async {
    _autoPlacesRetryCount = 0;
    _placesRetryDebounce?.cancel();
    _reloadDebounce?.cancel();

    final center = _centerForRoutePreview(preview);
    final destination = preview.destination;
    setState(() {
      _mapCenter = center;
      _userLocation = null;
      _targetPlace = null;
      _places = const [];
      _selectedPlace = null;
      _locationLabel = destination?.subtitle?.trim().isNotEmpty == true
          ? destination!.subtitle!.trim()
          : destination?.title;
      _locationIssueCode = null;
      _placesErrorMessage = null;
      _bootstrapping = false;
      _loadingPlaces = false;
      _hideInteractiveMarkersDuringCameraMove = false;
    });

    _focusRoutePreviewCamera(preview);
    _scheduleRoutePreviewCameraFit(preview);
    unawaited(_loadRoutePreviewUserLocation(requestPermission: true));
  }

  void _bootstrapActivityMarkersSync(MapActivityCollection collection) {
    _autoPlacesRetryCount = 0;
    _placesRetryDebounce?.cancel();
    _reloadDebounce?.cancel();

    final activities = collection.activities;
    final center = _centerForActivityMarkers(activities);
    final distance = const Distance();
    final places = [
      for (final activity in activities)
        _LocalPlace(
          id: 'activity:${activity.id}',
          title: activity.title,
          categoryValue: 'activity',
          categoryLabel: activity.categoryLabel,
          point: activity.point,
          distanceMeters: distance.as(LengthUnit.Meter, center, activity.point),
          detailRoute: activity.detailRoute,
          metaLabel: activity.metaLabel,
          startLabel: activity.startLabel,
          priceLabel: activity.priceLabel,
          markerIcon: activity.icon,
          avatarLabel: activity.avatarLabel,
          accentColor: activity.accentColor,
        ),
    ];

    _mapCenter = center;
    _userLocation = null;
    _targetPlace = null;
    _places = places;
    _selectedPlace = null;
    _locationLabel = collection.title;
    _locationIssueCode = null;
    _placesErrorMessage = null;
    _bootstrapping = false;
    _loadingPlaces = false;
    _hideInteractiveMarkersDuringCameraMove = false;

    _moveMap(center);
  }

  Future<void> _recenterToUser() async {
    if (_isRoutePreviewMode) {
      final preview = _routePreview;
      if (preview != null) {
        _focusRoutePreviewCamera(preview, animate: true);
      }
      return;
    }

    if (_showsActivityMarkers) {
      await _loadActivityUserLocation(
        requestPermission: true,
        moveCamera: true,
      );
      return;
    }

    setState(() {
      _locatingUser = true;
      _placesErrorMessage = null;
    });

    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion();
      if (suggestion == null) {
        throw Exception('location_unavailable');
      }
      if (!mounted) return;

      final center = LatLng(suggestion.latitude, suggestion.longitude);
      setState(() {
        _mapCenter = center;
        _userLocation = center;
        _locationLabel = _buildLocationLabel(suggestion);
        _locationIssueCode = null;
      });

      _moveMap(center);
      if (_showsActivityMarkers) {
        return;
      }
      await _loadPlaces(center, selectFirst: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationIssueCode = error.toString();
      });
      await _showError(
        _resolveLocationIssueMessage(AppLocalizations.of(context)!),
      );
    } finally {
      if (mounted) {
        setState(() {
          _locatingUser = false;
        });
      }
    }
  }

  Future<void> _loadActivityUserLocation({
    required bool requestPermission,
    required bool moveCamera,
  }) async {
    if (!_showsActivityMarkers) {
      return;
    }

    setState(() {
      _locatingUser = true;
      _locationIssueCode = null;
    });

    try {
      final coordinates = await _deviceContextService.detectCoordinates(
        requestPermission: requestPermission,
      );
      if (coordinates == null) {
        return;
      }
      if (!mounted) return;

      final userPoint = LatLng(coordinates.latitude, coordinates.longitude);
      setState(() {
        _userLocation = userPoint;
        _locationIssueCode = null;
        if (moveCamera) {
          _mapCenter = userPoint;
        }
      });

      if (moveCamera) {
        _moveMap(userPoint, animate: true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationIssueCode = error.toString();
      });
      if (requestPermission) {
        await _showError(
          _resolveLocationIssueMessage(AppLocalizations.of(context)!),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _locatingUser = false;
        });
      }
    }
  }

  Future<void> _loadTargetUserLocation({
    required bool requestPermission,
  }) async {
    if (_showsActivityMarkers || widget.initialTarget == null) {
      return;
    }

    setState(() {
      _locatingUser = true;
      _locationIssueCode = null;
    });

    try {
      final coordinates = await _deviceContextService.detectCoordinates(
        requestPermission: requestPermission,
      );
      if (coordinates == null) {
        return;
      }
      if (!mounted) return;

      final userPoint = LatLng(coordinates.latitude, coordinates.longitude);
      setState(() {
        _userLocation = userPoint;
        _locationIssueCode = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationIssueCode = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _locatingUser = false;
        });
      }
    }
  }

  Future<void> _loadRoutePreviewUserLocation({
    required bool requestPermission,
  }) async {
    if (!_isRoutePreviewMode) {
      return;
    }

    setState(() {
      _locatingUser = true;
      _locationIssueCode = null;
    });

    try {
      final coordinates = await _deviceContextService.detectCoordinates(
        requestPermission: requestPermission,
      );
      if (coordinates == null) {
        return;
      }
      if (!mounted) return;

      final userPoint = LatLng(coordinates.latitude, coordinates.longitude);
      setState(() {
        _userLocation = userPoint;
        _locationIssueCode = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationIssueCode = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _locatingUser = false;
        });
      }
    }
  }

  void _moveMap(
    LatLng center, {
    double zoom = _defaultZoom,
    bool animate = false,
  }) {
    final mapController = _mapController;
    if (!mounted ||
        _mapSuspendedForNavigation ||
        !_mapReady ||
        mapController == null) {
      return;
    }

    final target = _toGeographic(center);
    if (animate) {
      unawaited(
        mapController.animateCamera(
          center: target,
          zoom: zoom,
          nativeDuration: const Duration(milliseconds: 450),
          webMaxDuration: const Duration(milliseconds: 450),
        ),
      );
      return;
    }

    unawaited(mapController.moveCamera(center: target, zoom: zoom));
  }

  void _scheduleRoutePreviewCameraFit(
    MapRoutePreview preview, {
    bool animate = false,
  }) {
    _cancelRoutePreviewCameraFitRetry();

    void fitIfCurrent({required bool animated}) {
      if (!mounted ||
          _mapSuspendedForNavigation ||
          !identical(_routePreview, preview)) {
        return;
      }
      _focusRoutePreviewCamera(preview, animate: animated);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fitIfCurrent(animated: animate);
      _routePreviewCameraFitRetry = Timer(
        const Duration(milliseconds: 180),
        () => fitIfCurrent(animated: animate),
      );
      _routePreviewCameraFitLateRetry = Timer(
        const Duration(milliseconds: 650),
        () => fitIfCurrent(animated: false),
      );
    });
  }

  void _cancelRoutePreviewCameraFitRetry() {
    _routePreviewCameraFitRetry?.cancel();
    _routePreviewCameraFitRetry = null;
    _routePreviewCameraFitLateRetry?.cancel();
    _routePreviewCameraFitLateRetry = null;
  }

  void _focusRoutePreviewCamera(
    MapRoutePreview preview, {
    bool animate = false,
  }) {
    final bounds = _routePreviewBounds(preview);
    if (bounds == null) {
      _moveMap(_centerForRoutePreview(preview), animate: animate);
      return;
    }

    final mapController = _mapController;
    if (!mounted ||
        _mapSuspendedForNavigation ||
        !_mapReady ||
        mapController == null) {
      return;
    }

    final duration = animate
        ? const Duration(milliseconds: 450)
        : Duration.zero;
    unawaited(
      mapController.fitBounds(
        bounds: bounds,
        nativeDuration: duration,
        webMaxDuration: duration,
        webMaxZoom: 16,
        padding: EdgeInsets.all(_mapScaled(context, 56, min: 40, max: 72)),
      ),
    );
  }

  Future<void> _loadPlaces(LatLng center, {bool selectFirst = false}) async {
    if (_isRoutePreviewMode) return;

    _placesRetryDebounce?.cancel();
    setState(() {
      _loadingPlaces = true;
      _placesErrorMessage = null;
      _mapCenter = center;
    });

    try {
      final places = await _placesApi.fetchNearbyPlaces(
        center: center,
        radiusMeters: _searchRadiusMeters,
      );
      if (!mounted) return;

      final previousSelectionId = _selectedPlace?.id;
      _LocalPlace? selected = previousSelectionId == null
          ? null
          : places.cast<_LocalPlace?>().firstWhere(
              (place) => place?.id == previousSelectionId,
              orElse: () => null,
            );
      if (selected == null && _targetPlace?.id == previousSelectionId) {
        selected = _targetPlace;
      }

      if (selected == null && selectFirst && places.isNotEmpty) {
        selected = places.first;
      }

      setState(() {
        _places = places;
        _selectedPlace = selected;
      });
      _autoPlacesRetryCount = 0;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placesErrorMessage = 'nearby_places_load_failed';
        _places = const [];
        _selectedPlace = _targetPlace;
      });
      _schedulePlacesRetry(center, selectFirst: selectFirst);
    } finally {
      if (mounted) {
        setState(() {
          _loadingPlaces = false;
        });
      }
    }
  }

  void _schedulePlacesRetry(LatLng center, {required bool selectFirst}) {
    if (_autoPlacesRetryCount >= 2) {
      return;
    }

    _autoPlacesRetryCount += 1;
    _placesRetryDebounce?.cancel();
    _placesRetryDebounce = Timer(
      Duration(milliseconds: 900 * _autoPlacesRetryCount),
      () {
        if (!mounted || _loadingPlaces) return;
        unawaited(_loadPlaces(center, selectFirst: selectFirst));
      },
    );
  }

  void _handleMapEvent(MapEvent event) {
    if (!mounted || _mapSuspendedForNavigation) {
      return;
    }

    switch (event) {
      case MapEventStartMoveCamera(reason: final reason):
        _cameraChangeStartedByUser = reason == CameraChangeReason.apiGesture;
        if (_cameraChangeStartedByUser &&
            !_hideInteractiveMarkersDuringCameraMove) {
          setState(() {
            _hideInteractiveMarkersDuringCameraMove = true;
          });
        }
      case MapEventMoveCamera(camera: final camera):
        _handleMapCameraChanged(camera, hasGesture: _cameraChangeStartedByUser);
      case MapEventClick(point: final point, screenPoint: final screenPoint):
        if (_isRouteBuilderMode) {
          _handleRouteBuilderMapTap(point);
        } else {
          _selectRenderedPlaceAt(screenPoint);
        }
      case MapEventCameraIdle():
        _cameraChangeStartedByUser = false;
        if (_hideInteractiveMarkersDuringCameraMove) {
          setState(() {
            _hideInteractiveMarkersDuringCameraMove = false;
          });
        }
      default:
        break;
    }
  }

  void _handleMapCameraChanged(MapCamera camera, {required bool hasGesture}) {
    final center = _fromGeographic(camera.center);
    _mapCenter = center;
    if (!hasGesture || _hidesNearbyPlaces || _showsActivityMarkers) {
      return;
    }

    _placesRetryDebounce?.cancel();
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      unawaited(_loadPlaces(center));
    });
  }

  void _handleRouteBuilderMapTap(Geographic point) {
    final l10n = AppLocalizations.of(context)!;
    final nextOrder = _routeBuilderPoints.length + 1;
    final routePoint = RoutePointVm(
      latitude: point.lat.toDouble(),
      longitude: point.lon.toDouble(),
      name: l10n.mapRouteBuilderPointName(nextOrder),
    );

    setState(() {
      _routeBuilderPoints = [..._routeBuilderPoints, routePoint];
      _routePreview = null;
      _routeBuilderError = null;
      _savedRoutePreviewSignature = null;
      _selectedPlace = null;
    });
  }

  void _removeLastRouteBuilderPoint() {
    if (_routeBuilderPoints.isEmpty || _buildingCustomRoute) {
      return;
    }

    setState(() {
      _routeBuilderPoints = _routeBuilderPoints
          .take(_routeBuilderPoints.length - 1)
          .toList(growable: false);
      _routePreview = null;
      _routeBuilderError = null;
      _savedRoutePreviewSignature = null;
    });
  }

  void _clearRouteBuilder() {
    if ((_routeBuilderPoints.isEmpty && _routePreview == null) ||
        _buildingCustomRoute) {
      return;
    }

    setState(() {
      _routeBuilderPoints = const [];
      _routePreview = null;
      _routeBuilderError = null;
      _savedRoutePreviewSignature = null;
    });
  }

  Future<void> _buildCustomRoutePreview() async {
    final l10n = AppLocalizations.of(context)!;
    if (_routeBuilderPoints.length < 2 || _buildingCustomRoute) {
      setState(() {
        _routeBuilderError = l10n.mapRouteBuilderMinPoints;
      });
      return;
    }

    setState(() {
      _buildingCustomRoute = true;
      _routeBuilderError = null;
    });

    final routingProvider = context.read<RoutingProvider>();
    try {
      final route = await routingProvider.buildRoute(
        RouteRequestVm(
          profile: RouteProfile.touristWalk,
          points: _routeBuilderPoints,
        ),
      );
      if (!mounted) return;

      if (route == null) {
        setState(() {
          _routeBuilderError =
              routingProvider.errorMessage ?? l10n.mapRouteBuilderMinPoints;
        });
        return;
      }

      final preview = MapRoutePreview(
        route: route,
        routePoints: _routeBuilderPoints,
      );
      setState(() {
        _routePreview = preview;
      });
      _focusRoutePreviewCamera(preview, animate: true);
      _scheduleRoutePreviewCameraFit(preview, animate: true);
    } finally {
      if (mounted) {
        setState(() {
          _buildingCustomRoute = false;
        });
      }
    }
  }

  void _selectRenderedPlaceAt(Offset screenPoint) {
    final mapController = _mapController;
    if (_mapSuspendedForNavigation || !_mapReady || mapController == null) {
      return;
    }

    final features = mapController.featuresInRect(
      Rect.fromCenter(center: screenPoint, width: 44, height: 44),
    );
    for (final feature in features) {
      final placeId = feature.properties['placeId']?.toString();
      if (placeId == null || placeId.isEmpty) {
        continue;
      }
      final place = _findPlaceById(placeId);
      if (place == null) {
        continue;
      }
      _selectPlace(place);
      return;
    }
  }

  _LocalPlace? _findPlaceById(String id) {
    final targetPlace = _targetPlace;
    if (targetPlace?.id == id) {
      return targetPlace;
    }
    return _places.cast<_LocalPlace?>().firstWhere(
      (place) => place?.id == id,
      orElse: () => null,
    );
  }

  Future<void> _copyPlaceLink(_LocalPlace place) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: place.linkUrl));
    if (!mounted) return;
    _showSnack(l10n.mapPlaceLinkCopied);
  }

  void _selectPlace(_LocalPlace place, {bool animate = true}) {
    setState(() {
      _selectedPlace = place;
    });

    if (animate) {
      _moveMap(place.point, zoom: 16.2, animate: true);
    }
  }

  Future<void> _openPlaceDetails(_LocalPlace place) async {
    final route = place.detailRoute;
    if (route == null || _mapSuspendedForNavigation) {
      return;
    }

    _suspendNativeMapForRoute();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    try {
      await context.push(route);
    } finally {
      _resumeNativeMapAfterRoute();
    }
  }

  void _suspendNativeMapForRoute() {
    _reloadDebounce?.cancel();
    _placesRetryDebounce?.cancel();
    if (!mounted) {
      return;
    }

    setState(() {
      _mapSuspendedForNavigation = true;
      _mapReady = false;
      _mapController = null;
      _cameraChangeStartedByUser = false;
      _hideInteractiveMarkersDuringCameraMove = false;
    });
  }

  void _resumeNativeMapAfterRoute() {
    if (!mounted) {
      return;
    }

    setState(() {
      _mapViewGeneration += 1;
      _mapSuspendedForNavigation = false;
    });
  }

  Geographic _toGeographic(LatLng point) {
    return Geographic(lon: point.longitude, lat: point.latitude);
  }

  LatLng _fromGeographic(Geographic point) {
    return LatLng(point.lat.toDouble(), point.lon.toDouble());
  }

  List<Layer> _buildStableAnnotationLayers() {
    final layers = <Layer>[];
    final routePreview = _routePreview;
    if (routePreview != null) {
      final routeFeature = _routePolylineFeature(routePreview.route);
      if (routeFeature != null) {
        layers
          ..add(
            PolylineLayer(
              polylines: [routeFeature],
              color: Colors.white.withValues(alpha: 0.78),
              width: 8,
            ),
          )
          ..add(
            PolylineLayer(
              polylines: [routeFeature],
              color: AppColors.accent,
              width: 5,
            ),
          );
      }

      final stops = _routePreviewStops(routePreview);
      if (stops.isNotEmpty) {
        layers
          ..add(
            CircleLayer(
              points: [
                for (final stop in stops) _pointFeature(stop.id, stop.point),
              ],
              radius: 11,
              color: const Color(0xFFFFF7E6),
              strokeWidth: 3,
              strokeColor: AppColors.accent,
            ),
          )
          ..add(
            CircleLayer(
              points: [
                for (final stop in stops)
                  _pointFeature('${stop.id}:core', stop.point),
              ],
              radius: 5,
              color: AppColors.accent,
              strokeWidth: 1,
              strokeColor: const Color(0xFF3A2108),
            ),
          );
      }
    }

    final routeBuilderStops = routePreview == null && _isRouteBuilderMode
        ? _routeBuilderStops()
        : const <_RoutePreviewStop>[];
    if (routeBuilderStops.isNotEmpty) {
      layers
        ..add(
          CircleLayer(
            points: [
              for (final stop in routeBuilderStops)
                _pointFeature(stop.id, stop.point),
            ],
            radius: 11,
            color: const Color(0xFFFFF7E6),
            strokeWidth: 3,
            strokeColor: AppColors.accent,
          ),
        )
        ..add(
          CircleLayer(
            points: [
              for (final stop in routeBuilderStops)
                _pointFeature('${stop.id}:core', stop.point),
            ],
            radius: 5,
            color: AppColors.accent,
            strokeWidth: 1,
            strokeColor: const Color(0xFF3A2108),
          ),
        );
    }

    final userLocation = _userLocation;
    if (userLocation != null) {
      layers.add(
        CircleLayer(
          points: [_pointFeature('user-location', userLocation)],
          radius: 8,
          color: const Color(0xFF4BA8FF),
          strokeWidth: 3,
          strokeColor: Colors.white,
        ),
      );
    }

    final places = _hidesNearbyPlaces
        ? <_LocalPlace>[]
        : <_LocalPlace>[?_targetPlace, ..._places];
    if (places.isNotEmpty) {
      layers.add(
        CircleLayer(
          points: [for (final place in places) _placeFeature(place)],
          radius: _showsActivityMarkers ? 9 : 7,
          color: _showsActivityMarkers
              ? const Color(0xFFFFB44D)
              : const Color(0xFFF6E5D4),
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      );
    }

    final selectedPlace = _selectedPlace;
    if (selectedPlace != null && !_hidesNearbyPlaces) {
      layers.add(
        CircleLayer(
          points: [_placeFeature(selectedPlace)],
          radius: 13,
          color: AppColors.accent.withValues(alpha: 0.42),
          strokeWidth: 3,
          strokeColor: Colors.white,
        ),
      );
    }

    return layers;
  }

  Feature<Point> _placeFeature(_LocalPlace place) {
    return Feature(
      id: place.id,
      geometry: Point(_toGeographic(place.point)),
      properties: {'placeId': place.id},
    );
  }

  Feature<Point> _pointFeature(String id, LatLng point) {
    return Feature(
      id: id,
      geometry: Point(_toGeographic(point)),
      properties: {'pointId': id},
    );
  }

  Feature<LineString>? _routePolylineFeature(RouteResponseVm route) {
    final points = route.displayPoints;
    if (points.length < 2) {
      return null;
    }

    return Feature(
      id: 'route-preview',
      geometry: LineString.from([
        for (final point in points)
          Geographic(lon: point.longitude, lat: point.latitude),
      ]),
      properties: const {'routeId': 'route-preview'},
    );
  }

  LatLng _centerForRoutePreview(MapRoutePreview preview) {
    final routePoints = preview.route.displayPoints;
    if (routePoints.isNotEmpty) {
      return _centerForLatLngs(_routePointsToLatLngs(routePoints));
    }

    final stops = _routePreviewStops(preview);
    if (stops.isNotEmpty) {
      return _centerForLatLngs(stops.map((stop) => stop.point));
    }

    final destination = preview.destination;
    if (destination != null) {
      return destination.point;
    }

    final origin = preview.origin;
    if (origin != null) {
      return LatLng(origin.latitude, origin.longitude);
    }

    return _fallbackCenter;
  }

  Iterable<LatLng> _routePointsToLatLngs(Iterable<RoutePointVm> points) {
    return points.map((point) => LatLng(point.latitude, point.longitude));
  }

  LatLng _centerForLatLngs(Iterable<LatLng> points) {
    final iterator = points.iterator;
    if (!iterator.moveNext()) {
      return _fallbackCenter;
    }

    var minLat = iterator.current.latitude;
    var maxLat = iterator.current.latitude;
    var minLon = iterator.current.longitude;
    var maxLon = iterator.current.longitude;

    while (iterator.moveNext()) {
      final point = iterator.current;
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
  }

  LngLatBounds? _routePreviewBounds(MapRoutePreview preview) {
    final points = <Geographic>[];
    for (final point in preview.route.displayPoints) {
      _addRoutePreviewBoundPoint(
        points,
        LatLng(point.latitude, point.longitude),
      );
    }
    for (final stop in _routePreviewStops(preview)) {
      _addRoutePreviewBoundPoint(points, stop.point);
    }
    if (points.length < 2) {
      return null;
    }
    return LngLatBounds.fromPoints(points);
  }

  void _addRoutePreviewBoundPoint(List<Geographic> points, LatLng point) {
    final latitude = point.latitude;
    final longitude = point.longitude;
    if (!latitude.isFinite || !longitude.isFinite) {
      return;
    }

    const duplicateTolerance = 0.0000001;
    final alreadyIncluded = points.any(
      (existing) =>
          (existing.lat.toDouble() - latitude).abs() < duplicateTolerance &&
          (existing.lon.toDouble() - longitude).abs() < duplicateTolerance,
    );
    if (alreadyIncluded) {
      return;
    }

    points.add(Geographic(lon: longitude, lat: latitude));
  }

  List<_RoutePreviewStop> _routePreviewStops(MapRoutePreview preview) {
    if (preview.routePoints.isNotEmpty) {
      return [
        for (var i = 0; i < preview.routePoints.length; i++)
          _RoutePreviewStop(
            id: 'route-stop:$i',
            point: LatLng(
              preview.routePoints[i].latitude,
              preview.routePoints[i].longitude,
            ),
            order: i + 1,
            title: preview.routePoints[i].name,
          ),
      ];
    }

    final stops = <_RoutePreviewStop>[];
    final origin = preview.origin;
    if (origin != null) {
      stops.add(
        _RoutePreviewStop(
          id: 'route-stop:0',
          point: LatLng(origin.latitude, origin.longitude),
          order: 1,
          title: origin.name,
        ),
      );
    }
    final destination = preview.destination;
    if (destination != null) {
      stops.add(
        _RoutePreviewStop(
          id: 'route-stop:${stops.length}',
          point: destination.point,
          order: stops.length + 1,
          title: destination.title,
        ),
      );
    }
    return stops;
  }

  List<_RoutePreviewStop> _routeBuilderStops() {
    return [
      for (var i = 0; i < _routeBuilderPoints.length; i++)
        _RoutePreviewStop(
          id: 'route-builder-stop:$i',
          point: LatLng(
            _routeBuilderPoints[i].latitude,
            _routeBuilderPoints[i].longitude,
          ),
          order: i + 1,
          title: _routeBuilderPoints[i].name,
        ),
    ];
  }

  LatLng _centerForActivityMarkers(List<MapActivityTarget> activities) {
    if (activities.isEmpty) {
      return _fallbackCenter;
    }

    var minLat = activities.first.latitude;
    var maxLat = activities.first.latitude;
    var minLon = activities.first.longitude;
    var maxLon = activities.first.longitude;

    for (final activity in activities.skip(1)) {
      minLat = math.min(minLat, activity.latitude);
      maxLat = math.max(maxLat, activity.latitude);
      minLon = math.min(minLon, activity.longitude);
      maxLon = math.max(maxLon, activity.longitude);
    }

    return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showError(String message) {
    final l10n = AppLocalizations.of(context)!;
    return showErrorDialog(context, title: l10n.error, message: message);
  }

  Future<void> _saveRoutePreview() async {
    final preview = _routePreview;
    if (preview == null || _savingRoutePreview) {
      return;
    }

    final routePoints = _routePreviewSavePoints(preview);
    final l10n = AppLocalizations.of(context)!;
    if (routePoints.length < 2) {
      _showSnack(l10n.userRoutesSaveFailed);
      return;
    }

    setState(() {
      _savingRoutePreview = true;
    });

    final userRoutesProvider = context.read<UserRoutesProvider>();
    try {
      final savedRoute = await userRoutesProvider.createFromBuiltRoute(
        title: _routePreviewSaveTitle(preview, l10n),
        route: preview.route,
        points: routePoints,
        visibility: UserRouteVisibility.private,
      );
      if (!mounted) return;

      if (savedRoute == null) {
        _showSnack(
          userRoutesProvider.errorMessage ?? l10n.userRoutesSaveFailed,
        );
        return;
      }

      setState(() {
        _savedRoutePreviewSignature = _routePreviewSignature(preview);
      });
      _showSnack(l10n.userRoutesSaveSuccess);
    } finally {
      if (mounted) {
        setState(() {
          _savingRoutePreview = false;
        });
      }
    }
  }

  List<RoutePointVm> _routePreviewSavePoints(MapRoutePreview preview) {
    if (preview.routePoints.length >= 2) {
      return preview.routePoints;
    }

    final origin = preview.origin;
    final destination = preview.destination;
    if (origin != null && destination != null) {
      return [
        origin,
        RoutePointVm(
          latitude: destination.latitude,
          longitude: destination.longitude,
          name: destination.title,
        ),
      ];
    }

    final displayPoints = preview.route.displayPoints;
    if (displayPoints.length >= 2) {
      return [displayPoints.first, displayPoints.last];
    }

    return const [];
  }

  String _routePreviewSignature(MapRoutePreview preview) {
    final displayPoints = preview.route.displayPoints;
    return jsonEncode({
      'mode': preview.route.mode.backendValue,
      'profile': preview.route.profile.backendValue,
      'distanceMeters': preview.route.distanceMeters.round(),
      'durationSeconds': preview.route.durationSeconds,
      'points': [
        for (final point in _routePreviewSavePoints(preview))
          _routePointSignature(point),
      ],
      'displayPoints': [
        for (final point in displayPoints) _routePointSignature(point),
      ],
    });
  }

  Map<String, Object?> _routePointSignature(RoutePointVm point) {
    final name = point.name?.trim();
    return {
      'latitude': point.latitude.toStringAsFixed(6),
      'longitude': point.longitude.toStringAsFixed(6),
      if (name != null && name.isNotEmpty) 'name': name,
    };
  }

  String _routePreviewSaveTitle(
    MapRoutePreview preview,
    AppLocalizations l10n,
  ) {
    final destinationTitle = preview.destination?.title.trim();
    if (destinationTitle != null && destinationTitle.isNotEmpty) {
      return l10n.userRoutesDefaultTitleTo(destinationTitle);
    }

    final routePoints = _routePreviewSavePoints(preview);
    if (routePoints.isNotEmpty) {
      final lastPointName = routePoints.last.name?.trim();
      if (lastPointName != null && lastPointName.isNotEmpty) {
        return l10n.userRoutesDefaultTitleTo(lastPointName);
      }
    }

    return l10n.userRoutesDefaultTitle;
  }

  Future<void> _switchRouteProfile(RouteProfile profile) async {
    final preview = _routePreview;
    final origin = preview?.origin;
    final destination = preview?.destination;
    final routePointCount = preview?.routePoints.length ?? 0;
    final hasSwitchableRoute =
        routePointCount >= 2 || (origin != null && destination != null);
    if (preview == null ||
        !hasSwitchableRoute ||
        profile == preview.route.profile ||
        _switchingRouteProfile) {
      return;
    }

    final routePoints = preview.routePoints.isNotEmpty
        ? preview.routePoints
        : [
            origin!,
            RoutePointVm(
              latitude: destination!.latitude,
              longitude: destination.longitude,
              name: destination.title,
            ),
          ];
    final routingProvider = context.read<RoutingProvider>();
    final fallbackMessage = AppLocalizations.of(
      context,
    )!.mapUsingFallbackLocation;

    setState(() {
      _switchingRouteProfile = true;
      _routePreviewError = null;
    });

    try {
      final route = await routingProvider.buildRoute(
        RouteRequestVm(profile: profile, points: routePoints),
      );
      if (!mounted) return;

      if (route == null) {
        setState(() {
          _routePreviewError = routingProvider.errorMessage ?? fallbackMessage;
        });
        return;
      }

      final updatedPreview = MapRoutePreview(
        route: route,
        origin: origin,
        destination: destination,
        routePoints: routePoints,
        enabledProfiles: preview.enabledProfiles,
      );
      setState(() {
        _routePreview = updatedPreview;
        _savedRoutePreviewSignature = null;
      });
      _scheduleRoutePreviewCameraFit(updatedPreview, animate: true);
    } finally {
      if (mounted) {
        setState(() {
          _switchingRouteProfile = false;
        });
      }
    }
  }

  String? _buildLocationLabel(DeviceLocationSuggestion suggestion) {
    final city = suggestion.cityName?.trim();
    final country = suggestion.countryName?.trim();
    if (city != null &&
        city.isNotEmpty &&
        country != null &&
        country.isNotEmpty) {
      return '$city, $country';
    }
    if (city != null && city.isNotEmpty) {
      return city;
    }
    if (country != null && country.isNotEmpty) {
      return country;
    }
    return null;
  }

  String _resolveLocationIssueMessage(AppLocalizations l10n) {
    final code = _locationIssueCode ?? '';
    if (code.contains('location_services_disabled')) {
      return l10n.locationServicesDisabled;
    }
    if (code.contains('location_permission_denied_forever')) {
      return l10n.locationPermissionDeniedForever;
    }
    if (code.contains('location_permission_denied')) {
      return l10n.locationPermissionDenied;
    }
    return l10n.mapUsingFallbackLocation;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedPlace = _selectedPlace;
    final mapTitle = _isRouteBuilderMode
        ? l10n.mapRouteBuilderTitle
        : l10n.homeNavMap;
    final mapSubtitle = _isRouteBuilderMode
        ? l10n.mapRouteBuilderHint
        : _locationLabel ?? _resolveLocationIssueMessage(l10n);
    final placesCountLabel = _showsActivityMarkers
        ? l10n.mapActivitiesCount(_places.length)
        : l10n.mapPlacesCount(_places.length);
    final nearbyLabel = _showsActivityMarkers
        ? l10n.activitiesNearbyTitle
        : l10n.mapNearbyPlacesLabel;
    final tapHint = _showsActivityMarkers
        ? l10n.mapTapActivityHint
        : l10n.mapTapPlaceHint;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _MapResponsiveTextScope(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A120D), Color(0xFF120B07), Color(0xFF0F0906)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final routePreview = _routePreview;
                final routeBuilderPanel = _isRouteBuilderMode
                    ? _RouteBuilderPanel(
                        points: _routeBuilderPoints,
                        route: routePreview?.route,
                        building: _buildingCustomRoute,
                        savingRoute: _savingRoutePreview,
                        routeSaved: _routePreviewSaved,
                        showSaveRoute:
                            UserRouteFeatureFlags.customRoutesEnabled,
                        errorMessage: _routeBuilderError ?? _routePreviewError,
                        onBuildRoute: _buildCustomRoutePreview,
                        onRemoveLast: _removeLastRouteBuilderPoint,
                        onClear: _clearRouteBuilder,
                        onSaveRoute: routePreview == null
                            ? null
                            : _saveRoutePreview,
                      )
                    : null;
                final routePreviewPanel =
                    routePreview == null || _isRouteBuilderMode
                    ? null
                    : _RoutePreviewPanel(
                        preview: routePreview,
                        switching: _switchingRouteProfile,
                        savingRoute: _savingRoutePreview,
                        routeSaved: _routePreviewSaved,
                        showSaveRoute:
                            UserRouteFeatureFlags.customRoutesEnabled,
                        errorMessage: _routePreviewError,
                        onProfileChanged: _switchRouteProfile,
                        onSaveRoute: _saveRoutePreview,
                      );
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final compactHeight = screenHeight < 760 || textScale > 1.02;
                final ultraCompactHeight =
                    screenHeight < 690 || textScale > 1.12;
                final narrowScreen = screenWidth < 380;
                final outerPadding = _mapScaled(
                  context,
                  screenWidth < 360 ? 14 : 16,
                  min: 10,
                  max: 18,
                );
                final contentWidth = (constraints.maxWidth - (outerPadding * 2))
                    .clamp(0.0, double.infinity);
                final previewRailHeight = _mapScaled(
                  context,
                  ultraCompactHeight
                      ? 118
                      : narrowScreen
                      ? 126
                      : compactHeight
                      ? 120
                      : 130,
                  min: 112,
                  max: 138,
                );
                final hasRouteBottomPanel =
                    routePreviewPanel != null || routeBuilderPanel != null;
                final bottomPanelMaxHeight = math.min(
                  !hasRouteBottomPanel
                      ? screenHeight * (ultraCompactHeight ? 0.34 : 0.38)
                      : screenHeight * (ultraCompactHeight ? 0.42 : 0.46),
                  !hasRouteBottomPanel
                      ? _mapScaled(context, 278, min: 220, max: 292)
                      : _mapScaled(context, 340, min: 278, max: 360),
                );
                final topPadding = _mapScaled(
                  context,
                  ultraCompactHeight ? 10 : 14,
                  min: 8,
                  max: 16,
                );
                final sectionGap = _mapScaled(
                  context,
                  ultraCompactHeight
                      ? 10
                      : compactHeight
                      ? 12
                      : 14,
                  min: 8,
                  max: 16,
                );
                final mapRadius = _mapScaled(context, 30, min: 24, max: 32);

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    outerPadding,
                    topPadding,
                    outerPadding,
                    outerPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _MapHeaderButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => context.pop(),
                          ),
                          SizedBox(
                            width: _mapScaled(context, 14, min: 10, max: 16),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mapTitle,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: _mapScaled(
                                      context,
                                      24,
                                      min: 20,
                                      max: 24,
                                    ),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                SizedBox(
                                  height: _mapScaled(
                                    context,
                                    4,
                                    min: 2,
                                    max: 4,
                                  ),
                                ),
                                Text(
                                  mapSubtitle,
                                  maxLines: compactHeight ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: _mapScaled(
                                      context,
                                      14,
                                      min: 13,
                                      max: 14,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _MapHeaderButton(
                            icon: Icons.my_location_rounded,
                            onTap: _locatingUser ? null : _recenterToUser,
                            loading: _locatingUser,
                          ),
                        ],
                      ),
                      SizedBox(height: sectionGap),
                      Wrap(
                        spacing: _mapScaled(context, 10, min: 8, max: 10),
                        runSpacing: _mapScaled(context, 10, min: 8, max: 10),
                        children: [
                          if (_isRouteBuilderMode) ...[
                            _MapInfoChip(
                              icon: Icons.alt_route_rounded,
                              label: l10n.mapRouteBuilderTitle,
                              accent: true,
                            ),
                            _MapInfoChip(
                              icon: Icons.route_rounded,
                              label: l10n.userRoutesStopsCount(
                                _routeBuilderPoints.length,
                              ),
                            ),
                          ] else if (!_isRoutePreviewMode) ...[
                            _MapInfoChip(
                              icon: Icons.place_outlined,
                              label: placesCountLabel,
                            ),
                            _MapInfoChip(
                              icon: Icons.storefront_outlined,
                              label: nearbyLabel,
                            ),
                          ],
                          if (_locationIssueCode != null)
                            _MapInfoChip(
                              icon: Icons.info_outline_rounded,
                              label: l10n.mapUsingFallbackLocation,
                              accent: true,
                            ),
                        ],
                      ),
                      SizedBox(
                        height: _mapScaled(context, 16, min: 12, max: 18),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(mapRadius),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColoredBox(
                                      color: const Color(0xFFB3A28D),
                                      child: _mapSuspendedForNavigation
                                          ? const _MapNativeSuspendedPlaceholder()
                                          : MapLibreMap(
                                              key: ValueKey(
                                                'maplibre-$_mapViewGeneration',
                                              ),
                                              gestureRecognizers:
                                                  appMapGestureRecognizers(),
                                              options: MapOptions(
                                                initStyle:
                                                    AppConfig.mapStyleUrl,
                                                initCenter: _toGeographic(
                                                  _mapCenter,
                                                ),
                                                initZoom: _initialMapZoom,
                                                androidForegroundLoadColor:
                                                    const Color(0xFFB3A28D),
                                              ),
                                              onMapCreated: (controller) {
                                                if (!mounted ||
                                                    _mapSuspendedForNavigation) {
                                                  return;
                                                }
                                                _mapController = controller;
                                              },
                                              onStyleLoaded: (_) {
                                                if (!mounted ||
                                                    _mapSuspendedForNavigation) {
                                                  return;
                                                }
                                                _mapReady = true;
                                                final styleRoutePreview =
                                                    _routePreview;
                                                if (styleRoutePreview != null) {
                                                  _scheduleRoutePreviewCameraFit(
                                                    styleRoutePreview,
                                                  );
                                                } else {
                                                  _moveMap(_mapCenter);
                                                }
                                              },
                                              onEvent: _handleMapEvent,
                                              layers:
                                                  _buildStableAnnotationLayers(),
                                              children: [
                                                if (!_hideInteractiveMarkersDuringCameraMove)
                                                  WidgetLayer(
                                                    allowInteraction: true,
                                                    markers: [
                                                      if (routePreview != null)
                                                        for (final stop
                                                            in _routePreviewStops(
                                                              routePreview,
                                                            ))
                                                          Marker(
                                                            point:
                                                                _toGeographic(
                                                                  stop.point,
                                                                ),
                                                            size: Size.square(
                                                              _mapScaled(
                                                                context,
                                                                34,
                                                                min: 28,
                                                                max: 36,
                                                              ),
                                                            ),
                                                            child:
                                                                _RoutePointMarker(
                                                                  stop: stop,
                                                                ),
                                                          ),
                                                      if (routePreview ==
                                                              null &&
                                                          _isRouteBuilderMode)
                                                        for (final stop
                                                            in _routeBuilderStops())
                                                          Marker(
                                                            point:
                                                                _toGeographic(
                                                                  stop.point,
                                                                ),
                                                            size: Size.square(
                                                              _mapScaled(
                                                                context,
                                                                34,
                                                                min: 28,
                                                                max: 36,
                                                              ),
                                                            ),
                                                            child:
                                                                _RoutePointMarker(
                                                                  stop: stop,
                                                                ),
                                                          ),
                                                      if (_userLocation != null)
                                                        Marker(
                                                          point: _toGeographic(
                                                            _userLocation!,
                                                          ),
                                                          size: Size.square(
                                                            _mapScaled(
                                                              context,
                                                              32,
                                                              min: 26,
                                                              max: 34,
                                                            ),
                                                          ),
                                                          child:
                                                              const _UserLocationMarker(),
                                                        ),
                                                      if (_targetPlace !=
                                                              null &&
                                                          !_hidesNearbyPlaces)
                                                        Marker(
                                                          point: _toGeographic(
                                                            _targetPlace!.point,
                                                          ),
                                                          size: Size(
                                                            _mapScaled(
                                                              context,
                                                              58,
                                                              min: 48,
                                                              max: 60,
                                                            ),
                                                            _mapScaled(
                                                              context,
                                                              68,
                                                              min: 56,
                                                              max: 70,
                                                            ),
                                                          ),
                                                          alignment: Alignment
                                                              .topCenter,
                                                          child: _PlaceMarker(
                                                            place:
                                                                _targetPlace!,
                                                            selected:
                                                                selectedPlace
                                                                    ?.id ==
                                                                _targetPlace!
                                                                    .id,
                                                            onTap: () =>
                                                                _selectPlace(
                                                                  _targetPlace!,
                                                                ),
                                                          ),
                                                        ),
                                                      if (!_hidesNearbyPlaces)
                                                        for (final place
                                                            in _places)
                                                          Marker(
                                                            point:
                                                                _toGeographic(
                                                                  place.point,
                                                                ),
                                                            size: Size(
                                                              _mapScaled(
                                                                context,
                                                                52,
                                                                min: 42,
                                                                max: 54,
                                                              ),
                                                              _mapScaled(
                                                                context,
                                                                62,
                                                                min: 50,
                                                                max: 64,
                                                              ),
                                                            ),
                                                            alignment: Alignment
                                                                .topCenter,
                                                            child: _PlaceMarker(
                                                              place: place,
                                                              selected:
                                                                  selectedPlace
                                                                      ?.id ==
                                                                  place.id,
                                                              onTap: () =>
                                                                  _selectPlace(
                                                                    place,
                                                                  ),
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                AppMapAttribution(
                                                  padding: EdgeInsets.all(
                                                    _mapScaled(
                                                      context,
                                                      10,
                                                      min: 8,
                                                      max: 12,
                                                    ),
                                                  ),
                                                  alignment:
                                                      Alignment.bottomRight,
                                                ),
                                              ],
                                            ),
                                    ),
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                const Color(0x12000000),
                                                Colors.transparent,
                                                const Color(0x24000000),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: _mapScaled(
                                        context,
                                        16,
                                        min: 12,
                                        max: 18,
                                      ),
                                      left: _mapScaled(
                                        context,
                                        16,
                                        min: 12,
                                        max: 18,
                                      ),
                                      right: _mapScaled(
                                        context,
                                        16,
                                        min: 12,
                                        max: 18,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: _loadingPlaces
                                            ? _MapBanner(
                                                key: const ValueKey('loading'),
                                                icon: Icons.radar_rounded,
                                                label: l10n
                                                    .mapSearchingNearbyPlaces,
                                              )
                                            : _placesErrorMessage != null
                                            ? _MapBanner(
                                                key: const ValueKey('error'),
                                                icon:
                                                    Icons.error_outline_rounded,
                                                label: l10n.mapPlacesLoadFailed,
                                                actionLabel: l10n.retryButton,
                                                onActionTap: () => _loadPlaces(
                                                  _mapCenter,
                                                  selectFirst: true,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                    if (!_hidesNearbyPlaces &&
                                        !_bootstrapping &&
                                        !_loadingPlaces &&
                                        _places.isEmpty &&
                                        _placesErrorMessage == null &&
                                        _targetPlace == null)
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: _mapScaled(
                                              context,
                                              28,
                                              min: 18,
                                              max: 30,
                                            ),
                                          ),
                                          child: _MapEmptyState(
                                            title: l10n.mapNoPlacesTitle,
                                            subtitle: l10n.mapNoPlacesSubtitle,
                                          ),
                                        ),
                                      ),
                                    if (_bootstrapping)
                                      const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.accent,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            Flexible(
                              fit: FlexFit.tight,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: bottomPanelMaxHeight,
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: contentWidth,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (routeBuilderPanel != null) ...[
                                            routeBuilderPanel,
                                          ] else if (routePreviewPanel !=
                                              null) ...[
                                            routePreviewPanel,
                                          ] else ...[
                                            if (!_hidesNearbyPlaces &&
                                                _places.isNotEmpty) ...[
                                              SizedBox(
                                                height: previewRailHeight,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  itemCount: _places.length,
                                                  separatorBuilder: (_, _) =>
                                                      SizedBox(
                                                        width: _mapScaled(
                                                          context,
                                                          12,
                                                          min: 10,
                                                          max: 12,
                                                        ),
                                                      ),
                                                  itemBuilder: (context, index) {
                                                    final place =
                                                        _places[index];
                                                    return _PlacePreviewCard(
                                                      place: place,
                                                      selected:
                                                          selectedPlace?.id ==
                                                          place.id,
                                                      distanceLabel:
                                                          _formatDistance(
                                                            place,
                                                            l10n,
                                                          ),
                                                      onTap: () =>
                                                          _selectPlace(place),
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(height: sectionGap),
                                            ],
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: selectedPlace == null
                                                  ? _MapHintCard(
                                                      key: const ValueKey(
                                                        'hint',
                                                      ),
                                                      label: tapHint,
                                                    )
                                                  : _SelectedPlaceCard(
                                                      key: ValueKey(
                                                        selectedPlace.id,
                                                      ),
                                                      place: selectedPlace,
                                                      distanceLabel:
                                                          _formatDistance(
                                                            selectedPlace,
                                                            l10n,
                                                          ),
                                                      actionLabel:
                                                          selectedPlace
                                                                  .detailRoute ==
                                                              null
                                                          ? l10n.mapCopyPlaceLink
                                                          : l10n.activityViewDetails,
                                                      actionIcon:
                                                          selectedPlace
                                                                  .detailRoute ==
                                                              null
                                                          ? Icons.copy_rounded
                                                          : Icons
                                                                .arrow_forward_rounded,
                                                      onActionTap:
                                                          selectedPlace
                                                                  .detailRoute ==
                                                              null
                                                          ? () =>
                                                                _copyPlaceLink(
                                                                  selectedPlace,
                                                                )
                                                          : () => unawaited(
                                                              _openPlaceDetails(
                                                                selectedPlace,
                                                              ),
                                                            ),
                                                    ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDistance(_LocalPlace place, AppLocalizations l10n) {
    final origin = _showsActivityMarkers
        ? _userLocation
        : _userLocation ?? _mapCenter;
    if (origin == null) {
      return l10n.mapDistancePending;
    }

    final distanceMeters = _distance.as(LengthUnit.Meter, origin, place.point);

    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }
}

class _MapResponsiveTextScope extends StatelessWidget {
  const _MapResponsiveTextScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortSide = mediaQuery.size.shortestSide;
    final baseScale = mediaQuery.textScaler.scale(1);

    double widthScale;
    if (shortSide <= 320) {
      widthScale = 0.9;
    } else if (shortSide <= 360) {
      widthScale = 0.95;
    } else if (shortSide <= 390) {
      widthScale = 0.98;
    } else if (shortSide >= 430) {
      widthScale = 1.04;
    } else {
      widthScale = 1;
    }

    final effectiveScale = (baseScale * widthScale).clamp(0.9, 1.16);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: child,
    );
  }
}

class _MapNativeSuspendedPlaceholder extends StatelessWidget {
  const _MapNativeSuspendedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB3A28D), Color(0xFFCDBEA7), Color(0xFF8FA18B)],
        ),
      ),
    );
  }
}

class _RouteBuilderPanel extends StatelessWidget {
  const _RouteBuilderPanel({
    required this.points,
    required this.route,
    required this.building,
    required this.savingRoute,
    required this.routeSaved,
    required this.showSaveRoute,
    required this.errorMessage,
    required this.onBuildRoute,
    required this.onRemoveLast,
    required this.onClear,
    required this.onSaveRoute,
  });

  final List<RoutePointVm> points;
  final RouteResponseVm? route;
  final bool building;
  final bool savingRoute;
  final bool routeSaved;
  final bool showSaveRoute;
  final String? errorMessage;
  final VoidCallback onBuildRoute;
  final VoidCallback onRemoveLast;
  final VoidCallback onClear;
  final VoidCallback? onSaveRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final route = this.route;
    final canRemoveLast = points.isNotEmpty && !building && !savingRoute;
    final canClear =
        (points.isNotEmpty || route != null) && !building && !savingRoute;
    final message = errorMessage?.trim();

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF25170D).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.36)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_mapScaled(context, 14, min: 12, max: 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: _mapScaled(context, 40, min: 36, max: 42),
                    height: _mapScaled(context, 40, min: 36, max: 42),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.accent,
                      size: _mapScaled(context, 21, min: 18, max: 22),
                    ),
                  ),
                  SizedBox(width: _mapScaled(context, 10, min: 8, max: 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mapRouteBuilderTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          height: _mapScaled(context, 3, min: 2, max: 4),
                        ),
                        Text(
                          l10n.userRoutesStopsCount(points.length),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: _mapScaled(context, 10, min: 8, max: 12)),
              Text(
                points.length < 2
                    ? l10n.mapRouteBuilderMinPoints
                    : l10n.mapRouteBuilderHint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFF5DEC2),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (building) ...[
                SizedBox(height: _mapScaled(context, 10, min: 8, max: 10)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.accent,
                  ),
                ),
              ],
              if (message != null && message.isNotEmpty) ...[
                SizedBox(height: _mapScaled(context, 10, min: 8, max: 10)),
                _RoutePreviewErrorMessage(message: message),
              ],
              if (route != null) ...[
                SizedBox(height: _mapScaled(context, 10, min: 8, max: 12)),
                RouteSummaryCard(route: route),
              ],
              SizedBox(height: _mapScaled(context, 12, min: 10, max: 14)),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: building || savingRoute ? null : onBuildRoute,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF241100),
                    disabledBackgroundColor: AppColors.accent.withValues(
                      alpha: 0.46,
                    ),
                    disabledForegroundColor: const Color(
                      0xFF241100,
                    ).withValues(alpha: 0.58),
                    padding: EdgeInsets.symmetric(
                      horizontal: _mapScaled(context, 14, min: 12, max: 16),
                      vertical: _mapScaled(context, 12, min: 10, max: 13),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: building
                      ? SizedBox.square(
                          dimension: _mapScaled(context, 16, min: 14, max: 16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF241100),
                          ),
                        )
                      : const Icon(Icons.route_rounded),
                  label: Text(
                    l10n.mapRouteBuilderBuildRoute,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: _mapScaled(context, 8, min: 6, max: 10)),
              LayoutBuilder(
                builder: (context, constraints) {
                  final removeButton = OutlinedButton.icon(
                    onPressed: canRemoveLast ? onRemoveLast : null,
                    style: _routeBuilderSecondaryButtonStyle(context),
                    icon: const Icon(Icons.undo_rounded),
                    label: Text(
                      l10n.mapRouteBuilderRemoveLast,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                  final clearButton = OutlinedButton.icon(
                    onPressed: canClear ? onClear : null,
                    style: _routeBuilderSecondaryButtonStyle(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(
                      l10n.mapRouteBuilderClear,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        removeButton,
                        SizedBox(
                          height: _mapScaled(context, 8, min: 6, max: 8),
                        ),
                        clearButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: removeButton),
                      SizedBox(width: _mapScaled(context, 8, min: 6, max: 10)),
                      Expanded(child: clearButton),
                    ],
                  );
                },
              ),
              if (showSaveRoute && route != null) ...[
                SizedBox(height: _mapScaled(context, 8, min: 6, max: 10)),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: building || savingRoute || routeSaved
                        ? null
                        : onSaveRoute,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF1D6),
                      disabledBackgroundColor: const Color(
                        0xFFFFF1D6,
                      ).withValues(alpha: 0.58),
                      foregroundColor: AppColors.textPrimary,
                      disabledForegroundColor: AppColors.textPrimary.withValues(
                        alpha: 0.58,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: _mapScaled(context, 14, min: 12, max: 16),
                        vertical: _mapScaled(context, 12, min: 10, max: 13),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: savingRoute
                        ? SizedBox.square(
                            dimension: _mapScaled(
                              context,
                              16,
                              min: 14,
                              max: 16,
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : routeSaved
                        ? const Icon(Icons.check_circle_rounded)
                        : const Icon(Icons.bookmark_add_rounded),
                    label: Text(
                      routeSaved
                          ? l10n.userRoutesRouteSaved
                          : l10n.userRoutesSaveRoute,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _routeBuilderSecondaryButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFFE1AE),
      disabledForegroundColor: const Color(0xFFFFE1AE).withValues(alpha: 0.38),
      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.42)),
      padding: EdgeInsets.symmetric(
        horizontal: _mapScaled(context, 12, min: 10, max: 14),
        vertical: _mapScaled(context, 11, min: 9, max: 12),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _RoutePreviewPanel extends StatelessWidget {
  const _RoutePreviewPanel({
    required this.preview,
    required this.switching,
    required this.savingRoute,
    required this.routeSaved,
    required this.showSaveRoute,
    required this.errorMessage,
    required this.onProfileChanged,
    required this.onSaveRoute,
  });

  final MapRoutePreview preview;
  final bool switching;
  final bool savingRoute;
  final bool routeSaved;
  final bool showSaveRoute;
  final String? errorMessage;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback onSaveRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSwitchProfiles =
        preview.routePoints.length >= 2 ||
        (preview.origin != null && preview.destination != null);
    final message = errorMessage;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canSwitchProfiles) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.36),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(_mapScaled(context, 6, min: 4, max: 6)),
                child: RouteModeSelector(
                  selected: preview.route.profile,
                  enabledProfiles: preview.enabledProfiles,
                  onChanged: onProfileChanged,
                ),
              ),
            ),
            SizedBox(height: _mapScaled(context, 8, min: 6, max: 8)),
          ],
          if (switching) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: _mapScaled(context, 8, min: 6, max: 8)),
          ],
          if (message != null && message.trim().isNotEmpty) ...[
            _RoutePreviewErrorMessage(message: message),
            SizedBox(height: _mapScaled(context, 8, min: 6, max: 8)),
          ],
          RouteSummaryCard(route: preview.route),
          if (showSaveRoute) ...[
            SizedBox(height: _mapScaled(context, 10, min: 8, max: 12)),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: switching || savingRoute || routeSaved
                    ? null
                    : onSaveRoute,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor: AppColors.accent.withValues(
                    alpha: 0.46,
                  ),
                  disabledForegroundColor: AppColors.textPrimary.withValues(
                    alpha: 0.58,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: _mapScaled(context, 14, min: 12, max: 16),
                    vertical: _mapScaled(context, 12, min: 10, max: 13),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: savingRoute
                    ? SizedBox.square(
                        dimension: _mapScaled(context, 16, min: 14, max: 16),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : routeSaved
                    ? const Icon(Icons.check_circle_rounded)
                    : const Icon(Icons.bookmark_add_rounded),
                label: Text(
                  routeSaved
                      ? l10n.userRoutesRouteSaved
                      : l10n.userRoutesSaveRoute,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePreviewErrorMessage extends StatelessWidget {
  const _RoutePreviewErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _mapScaled(context, 12, min: 10, max: 12),
          vertical: _mapScaled(context, 10, min: 8, max: 10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.route_outlined,
              color: theme.colorScheme.onErrorContainer,
              size: _mapScaled(context, 18, min: 16, max: 18),
            ),
            SizedBox(width: _mapScaled(context, 8, min: 6, max: 8)),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _mapUiScale(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final shortSide = mediaQuery.size.shortestSide;
  final height = mediaQuery.size.height;

  double scale;
  if (shortSide <= 320) {
    scale = 0.88;
  } else if (shortSide <= 360) {
    scale = 0.94;
  } else if (shortSide <= 390) {
    scale = 0.98;
  } else if (shortSide >= 430) {
    scale = 1.04;
  } else {
    scale = 1;
  }

  if (height < 700) {
    scale *= 0.96;
  } else if (height > 920) {
    scale *= 1.02;
  }

  return scale.clamp(0.86, 1.08);
}

double _mapScaled(
  BuildContext context,
  double value, {
  double? min,
  double? max,
}) {
  final scaled = value * _mapUiScale(context);
  if (min == null && max == null) {
    return scaled;
  }
  return scaled.clamp(min ?? scaled, max ?? scaled);
}

class _MapHeaderButton extends StatelessWidget {
  const _MapHeaderButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final buttonSize = _mapScaled(context, 44, min: 38, max: 46);
    final iconSize = _mapScaled(context, 18, min: 16, max: 18);
    final progressSize = _mapScaled(context, 18, min: 16, max: 18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: progressSize,
                    height: progressSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                : Icon(icon, color: AppColors.textPrimary, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _MapInfoChip extends StatelessWidget {
  const _MapInfoChip({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final foreground = accent ? AppColors.textPrimary : const Color(0xFFF4E8DA);
    final maxWidth = (MediaQuery.sizeOf(context).width - 32)
        .clamp(140.0, 360.0)
        .toDouble();
    final horizontalPadding = _mapScaled(context, 14, min: 10, max: 14);
    final verticalPadding = _mapScaled(context, 9, min: 7, max: 9);
    final iconSize = _mapScaled(context, 16, min: 14, max: 16);
    final labelSpacing = _mapScaled(context, 8, min: 6, max: 8);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: accent
              ? const LinearGradient(
                  colors: [Color(0xFFFFB44D), Color(0xFFFF9800)],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
          border: accent
              ? null
              : Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: foreground),
            SizedBox(width: labelSpacing),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: _mapScaled(context, 13, min: 11.5, max: 13),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapBanner extends StatelessWidget {
  const _MapBanner({
    super.key,
    required this.icon,
    required this.label,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String label;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _mapScaled(context, 14, min: 12, max: 14);
    final topPadding = _mapScaled(context, 12, min: 10, max: 12);
    final bottomPadding = _mapScaled(context, 12, min: 10, max: 12);
    final radius = _mapScaled(context, 20, min: 18, max: 20);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 340 || textScale > 1.08;

        return Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          decoration: BoxDecoration(
            color: const Color(0xD423150B),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: _mapScaled(context, 1, min: 0, max: 1),
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.accent,
                            size: _mapScaled(context, 18, min: 16, max: 18),
                          ),
                        ),
                        SizedBox(
                          width: _mapScaled(context, 10, min: 8, max: 10),
                        ),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: _mapScaled(
                                context,
                                14,
                                min: 13,
                                max: 14,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (actionLabel != null && onActionTap != null) ...[
                      SizedBox(
                        height: _mapScaled(context, 10, min: 8, max: 10),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onActionTap,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            minimumSize: Size(
                              0,
                              _mapScaled(context, 36, min: 34, max: 38),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: _mapScaled(
                                context,
                                10,
                                min: 8,
                                max: 10,
                              ),
                              vertical: _mapScaled(context, 6, min: 4, max: 6),
                            ),
                          ),
                          child: Text(actionLabel!),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: AppColors.accent,
                      size: _mapScaled(context, 18, min: 16, max: 18),
                    ),
                    SizedBox(width: _mapScaled(context, 10, min: 8, max: 10)),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: _mapScaled(context, 14, min: 13, max: 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (actionLabel != null && onActionTap != null) ...[
                      SizedBox(width: _mapScaled(context, 12, min: 8, max: 12)),
                      TextButton(
                        onPressed: onActionTap,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          minimumSize: Size(
                            0,
                            _mapScaled(context, 36, min: 34, max: 38),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: _mapScaled(
                              context,
                              10,
                              min: 8,
                              max: 10,
                            ),
                            vertical: _mapScaled(context, 6, min: 4, max: 6),
                          ),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final circleSize = _mapScaled(context, 60, min: 48, max: 60);

    return Container(
      padding: EdgeInsets.fromLTRB(
        _mapScaled(context, 18, min: 14, max: 18),
        _mapScaled(context, 20, min: 16, max: 20),
        _mapScaled(context, 18, min: 14, max: 18),
        _mapScaled(context, 18, min: 14, max: 18),
      ),
      decoration: BoxDecoration(
        color: const Color(0xD723160D),
        borderRadius: BorderRadius.circular(
          _mapScaled(context, 24, min: 20, max: 24),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              color: AppColors.accent,
              size: _mapScaled(context, 28, min: 22, max: 28),
            ),
          ),
          SizedBox(height: _mapScaled(context, 14, min: 10, max: 14)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: _mapScaled(context, 20, min: 17, max: 20),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: _mapScaled(context, 8, min: 6, max: 8)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xB3FFF0E0),
              fontSize: _mapScaled(context, 14, min: 13, max: 14),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePreviewStop {
  const _RoutePreviewStop({
    required this.id,
    required this.point,
    required this.order,
    this.title,
  });

  final String id;
  final LatLng point;
  final int order;
  final String? title;
}

class _RoutePointMarker extends StatelessWidget {
  const _RoutePointMarker({required this.stop});

  final _RoutePreviewStop stop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: stop.title?.trim().isNotEmpty == true
          ? stop.title!.trim()
          : l10n.routeStopSemantic(stop.order),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFF7E6),
          border: Border.all(color: const Color(0xFF3A2108), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            stop.order.toString(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: _mapScaled(context, 13, min: 11, max: 13),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    final dotSize = _mapScaled(context, 16, min: 13, max: 16);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Center(
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4BA8FF),
            border: Border.all(
              color: Colors.white,
              width: _mapScaled(context, 2, min: 1.5, max: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final _LocalPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pinSize = _mapScaled(
      context,
      selected ? 36 : 32,
      min: selected ? 30 : 28,
      max: selected ? 36 : 32,
    );
    final markerColor = selected
        ? AppColors.accent
        : place.accentColor ?? const Color(0xFFF6E5D4);
    final markerForeground = selected
        ? AppColors.textPrimary
        : place.accentColor == null
        ? const Color(0xFF6A3D0B)
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: pinSize,
            height: pinSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: markerColor,
              border: Border.all(
                color: selected ? Colors.white : const Color(0xFFFFB44D),
                width: _mapScaled(context, 2, min: 1.5, max: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: _mapScaled(context, 14, min: 10, max: 14),
                  offset: Offset(0, _mapScaled(context, 8, min: 5, max: 8)),
                ),
              ],
            ),
            child: Center(
              child: place.avatarLabel == null
                  ? Icon(
                      place.icon,
                      size: _mapScaled(context, 17, min: 14, max: 17),
                      color: markerForeground,
                    )
                  : Text(
                      place.avatarLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: markerForeground,
                        fontSize: _mapScaled(context, 12, min: 10, max: 12),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          Container(
            width: _mapScaled(context, 3, min: 2.5, max: 3),
            height: _mapScaled(context, 14, min: 10, max: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : const Color(0xFFFFB44D),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacePreviewCard extends StatelessWidget {
  const _PlacePreviewCard({
    required this.place,
    required this.selected,
    required this.distanceLabel,
    required this.onTap,
  });

  final _LocalPlace place;
  final bool selected;
  final String distanceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = _mapScaled(context, 196, min: 158, max: 204);
    final radius = _mapScaled(context, 24, min: 20, max: 24);

    return SizedBox(
      width: cardWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final screenWidth = MediaQuery.sizeOf(context).width;
          final compactCard =
              screenWidth < 380 ||
              constraints.maxHeight <
                  _mapScaled(context, 118, min: 112, max: 118) ||
              textScale > 1.02;
          final showCategory =
              place.categoryValue == 'activity' ||
              (constraints.maxHeight >=
                      _mapScaled(context, 116, min: 108, max: 116) &&
                  textScale <= 1.14);
          final iconBadgeSize = _mapScaled(
            context,
            compactCard ? 32 : 36,
            min: compactCard ? 28 : 30,
            max: compactCard ? 32 : 36,
          );
          final topPadding = _mapScaled(
            context,
            compactCard ? 12 : 14,
            min: 10,
            max: 14,
          );
          final bottomPadding = _mapScaled(
            context,
            compactCard ? 10 : 12,
            min: 8,
            max: 12,
          );
          final titleGap = _mapScaled(
            context,
            compactCard ? 8 : 12,
            min: 6,
            max: 12,
          );
          final categoryGap = _mapScaled(
            context,
            compactCard ? 6 : 8,
            min: 4,
            max: 8,
          );

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Ink(
                padding: EdgeInsets.fromLTRB(
                  _mapScaled(context, 14, min: 11, max: 14),
                  topPadding,
                  _mapScaled(context, 14, min: 11, max: 14),
                  bottomPadding,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB44D), Color(0xFFFF9800)],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.accent.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: iconBadgeSize,
                          height: iconBadgeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.18)
                                : AppColors.accent.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            place.icon,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.accent,
                            size: _mapScaled(context, 18, min: 15, max: 18),
                          ),
                        ),
                        SizedBox(
                          width: _mapScaled(context, 10, min: 6, max: 10),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              distanceLabel,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.textPrimary.withValues(
                                        alpha: 0.78,
                                      )
                                    : const Color(0xB3FFF0E0),
                                fontSize: _mapScaled(
                                  context,
                                  12,
                                  min: 11,
                                  max: 12,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: titleGap),
                    Text(
                      place.title,
                      maxLines: compactCard || !showCategory ? 1 : 2,
                      softWrap: !compactCard,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: _mapScaled(
                          context,
                          compactCard ? 14 : 15,
                          min: 13,
                          max: 15,
                        ),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (showCategory) ...[
                      SizedBox(height: categoryGap),
                      Text(
                        place.categoryLabel,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors.textPrimary.withValues(alpha: 0.72)
                              : const Color(0xA8FFF0E0),
                          fontSize: _mapScaled(context, 13, min: 12, max: 13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapHintCard extends StatelessWidget {
  const _MapHintCard({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _mapScaled(context, 18, min: 14, max: 18),
        _mapScaled(context, 16, min: 12, max: 16),
        _mapScaled(context, 18, min: 14, max: 18),
        _mapScaled(context, 16, min: 12, max: 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(
          _mapScaled(context, 24, min: 20, max: 24),
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _mapScaled(context, 40, min: 34, max: 40),
            height: _mapScaled(context, 40, min: 34, max: 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.touch_app_rounded,
              color: AppColors.accent,
              size: _mapScaled(context, 18, min: 15, max: 18),
            ),
          ),
          SizedBox(width: _mapScaled(context, 12, min: 10, max: 12)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: _mapScaled(context, 14, min: 13, max: 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({
    super.key,
    required this.place,
    required this.distanceLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.onActionTap,
  });

  final _LocalPlace place;
  final String distanceLabel;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final radius = _mapScaled(context, 26, min: 22, max: 26);
    final buttonHeight = _mapScaled(context, 46, min: 40, max: 46);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _mapScaled(context, 18, min: 14, max: 18),
        _mapScaled(context, 18, min: 14, max: 18),
        _mapScaled(context, 18, min: 14, max: 18),
        _mapScaled(context, 18, min: 14, max: 18),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.14)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final button = FilledButton.tonal(
            onPressed: onActionTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.18),
              foregroundColor: AppColors.accent,
              minimumSize: Size(0, buttonHeight),
              padding: EdgeInsets.symmetric(
                horizontal: _mapScaled(context, 16, min: 12, max: 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _mapScaled(context, 18, min: 16, max: 18),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  actionIcon,
                  size: _mapScaled(context, 16, min: 14, max: 16),
                ),
                SizedBox(width: _mapScaled(context, 8, min: 6, max: 8)),
                Flexible(
                  child: Text(actionLabel, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );

          final avatarSize = constraints.maxWidth < 340
              ? _mapScaled(context, 42, min: 38, max: 42)
              : _mapScaled(context, 48, min: 40, max: 48);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (place.accentColor ?? AppColors.accent).withValues(
                        alpha: 0.16,
                      ),
                    ),
                    child: _SelectedPlaceAvatar(place: place),
                  ),
                  SizedBox(width: _mapScaled(context, 12, min: 10, max: 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          place.title,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: _mapScaled(context, 16, min: 14, max: 16),
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                        SizedBox(
                          height: _mapScaled(context, 6, min: 4, max: 6),
                        ),
                        _SelectedPlaceMeta(
                          place: place,
                          distanceLabel: distanceLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: _mapScaled(context, 14, min: 10, max: 14)),
              SizedBox(width: double.infinity, child: button),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedPlaceMeta extends StatelessWidget {
  const _SelectedPlaceMeta({required this.place, required this.distanceLabel});

  final _LocalPlace place;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    final secondaryParts = [
      ?place.startLabel?.trim(),
      ?place.priceLabel?.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${place.categoryLabel} · $distanceLabel',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xB3FFF0E0),
            fontSize: _mapScaled(context, 13, min: 12, max: 13),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (secondaryParts.isNotEmpty) ...[
          SizedBox(height: _mapScaled(context, 3, min: 2, max: 4)),
          Text(
            secondaryParts.join(' · '),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0x99FFF0E0),
              fontSize: _mapScaled(context, 12, min: 11, max: 12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedPlaceAvatar extends StatelessWidget {
  const _SelectedPlaceAvatar({required this.place});

  final _LocalPlace place;

  @override
  Widget build(BuildContext context) {
    if (place.avatarLabel != null) {
      return Center(
        child: Text(
          place.avatarLabel!,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: place.accentColor ?? AppColors.accent,
            fontSize: _mapScaled(context, 16, min: 14, max: 16),
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Icon(
      place.icon,
      color: place.accentColor ?? AppColors.accent,
      size: _mapScaled(context, 22, min: 18, max: 22),
    );
  }
}

class _NearbyPlacesApi {
  _NearbyPlacesApi()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
          sendTimeout: const Duration(seconds: 15),
          contentType: 'text/plain',
          responseType: ResponseType.plain,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'Inflap/1.0 (nearby places)',
          },
        ),
      );

  final Dio _dio;
  static const int _nearbyPlacesPrimaryLimit = 160;
  static const int _nearbyPlacesFallbackLimit = 96;
  static const int _nearbyPlacesCompactFallbackLimit = 64;
  static final List<Uri> _publicEndpoints = [
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://maps.mail.ru/osm/tools/overpass/api/interpreter'),
  ];

  Future<List<_LocalPlace>> fetchNearbyPlaces({
    required LatLng center,
    required int radiusMeters,
  }) async {
    final attempts = <_NearbyPlacesRequest>[
      for (final endpoint in _publicEndpoints)
        _NearbyPlacesRequest(
          endpoint: endpoint,
          radiusMeters: radiusMeters,
          resultLimit: _nearbyPlacesPrimaryLimit,
        ),
      for (final endpoint in _publicEndpoints)
        _NearbyPlacesRequest(
          endpoint: endpoint,
          radiusMeters: (radiusMeters * 0.66).round(),
          resultLimit: _nearbyPlacesFallbackLimit,
        ),
      for (final endpoint in _publicEndpoints)
        _NearbyPlacesRequest(
          endpoint: endpoint,
          radiusMeters: (radiusMeters * 0.5).round(),
          resultLimit: _nearbyPlacesCompactFallbackLimit,
        ),
    ];

    Object? lastError;
    StackTrace? lastStackTrace;

    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      try {
        final response = await _dio.postUri(
          attempt.endpoint,
          data: _buildQuery(
            center: center,
            radiusMeters: attempt.radiusMeters,
            resultLimit: attempt.resultLimit,
          ),
        );
        final root = _decodeRoot(response.data);
        if (root == null) {
          throw const FormatException('invalid nearby places response');
        }

        return _parsePlaces(root: root, center: center);
      } on DioException catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (!_shouldRetry(error) || i == attempts.length - 1) {
          break;
        }
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (i == attempts.length - 1) {
          break;
        }
      }

      await Future<void>.delayed(Duration(milliseconds: 280 * (i + 1)));
    }

    Error.throwWithStackTrace(
      Exception('nearby_places_load_failed: $lastError'),
      lastStackTrace ?? StackTrace.current,
    );
  }

  static String _buildQuery({
    required LatLng center,
    required int radiusMeters,
    required int resultLimit,
  }) {
    return '''
[out:json][timeout:20];
(
  node["amenity"~"cafe|restaurant|fast_food|bar|pub|pharmacy|hospital|clinic|bank|atm|fuel|cinema|theatre|library|marketplace"](around:$radiusMeters,${center.latitude},${center.longitude});
  node["shop"](around:$radiusMeters,${center.latitude},${center.longitude});
  node["tourism"~"hotel|museum|place|viewpoint|gallery|guest_house|apartment"](around:$radiusMeters,${center.latitude},${center.longitude});
  node["leisure"~"park|fitness_centre|sports_centre"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["amenity"~"cafe|restaurant|fast_food|bar|pub|pharmacy|hospital|clinic|bank|atm|fuel|cinema|theatre|library|marketplace"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["shop"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["tourism"~"hotel|museum|place|viewpoint|gallery|guest_house|apartment"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["leisure"~"park|fitness_centre|sports_centre"](around:$radiusMeters,${center.latitude},${center.longitude});
);
out center $resultLimit;
''';
  }

  static Map<String, dynamic>? _decodeRoot(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }

  static List<_LocalPlace> _parsePlaces({
    required Map<String, dynamic> root,
    required LatLng center,
  }) {
    final rawElements = root['elements'];
    if (rawElements is! List) {
      return const [];
    }

    final places = <_LocalPlace>[];
    final dedupe = <String>{};
    final distance = const Distance();

    for (final rawElement in rawElements) {
      if (rawElement is! Map) continue;

      final element = rawElement.cast<String, dynamic>();
      final tags =
          (element['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
      final lat =
          (element['lat'] as num?)?.toDouble() ??
          (element['center'] as Map?)?['lat'] as num?;
      final lon =
          (element['lon'] as num?)?.toDouble() ??
          (element['center'] as Map?)?['lon'] as num?;
      if (lat == null || lon == null) {
        continue;
      }

      final point = LatLng(
        lat is double ? lat : lat.toDouble(),
        lon is double ? lon : lon.toDouble(),
      );
      final categoryValue = _firstNonEmptyTag(tags);
      final title = _resolveTitle(tags, categoryValue);
      final id = '${element['type']}-${element['id']}';
      final dedupeKey =
          '${title.toLowerCase()}-${point.latitude.toStringAsFixed(4)}-${point.longitude.toStringAsFixed(4)}';
      if (!dedupe.add(dedupeKey)) {
        continue;
      }

      places.add(
        _LocalPlace(
          id: id,
          title: title,
          categoryValue: categoryValue,
          categoryLabel: _humanizeCategory(categoryValue),
          point: point,
          distanceMeters: distance.as(LengthUnit.Meter, center, point),
        ),
      );
    }

    places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return places;
  }

  static bool _shouldRetry(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return true;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == null) {
      return true;
    }

    return statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  static String _firstNonEmptyTag(Map<String, dynamic> tags) {
    for (final key in ['amenity', 'shop', 'tourism', 'leisure']) {
      final value = tags[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return 'place';
  }

  static String _resolveTitle(Map<String, dynamic> tags, String categoryValue) {
    final name = tags['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return _humanizeCategory(categoryValue);
  }

  static String _humanizeCategory(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'fast_food':
        return 'Fast food';
      case 'guest_house':
        return 'Guest house';
      case 'fitness_centre':
        return 'Fitness centre';
      case 'sports_centre':
        return 'Sports centre';
      default:
        return normalized
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }
}

class _NearbyPlacesRequest {
  const _NearbyPlacesRequest({
    required this.endpoint,
    required this.radiusMeters,
    required this.resultLimit,
  });

  final Uri endpoint;
  final int radiusMeters;
  final int resultLimit;
}

class _LocalPlace {
  const _LocalPlace({
    required this.id,
    required this.title,
    required this.categoryValue,
    required this.categoryLabel,
    required this.point,
    required this.distanceMeters,
    this.detailRoute,
    this.metaLabel,
    this.startLabel,
    this.priceLabel,
    this.markerIcon,
    this.avatarLabel,
    this.accentColor,
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String categoryValue;
  final String categoryLabel;
  final LatLng point;
  final double distanceMeters;
  final String? detailRoute;
  final String? metaLabel;
  final String? startLabel;
  final String? priceLabel;
  final IconData? markerIcon;
  final String? avatarLabel;
  final Color? accentColor;
  final String? sourceUrl;

  String get linkUrl {
    final url = sourceUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return AppMapLinks.buildUrl(
      latitude: point.latitude,
      longitude: point.longitude,
      title: title,
      subtitle: categoryLabel,
    );
  }

  IconData get icon {
    if (markerIcon != null) {
      return markerIcon!;
    }

    switch (categoryValue.toLowerCase()) {
      case 'activity':
        return Icons.event_available_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'restaurant':
      case 'fast_food':
        return Icons.restaurant_rounded;
      case 'bar':
      case 'pub':
        return Icons.wine_bar_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital_rounded;
      case 'bank':
      case 'atm':
        return Icons.account_balance_wallet_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'hotel':
      case 'guest_house':
      case 'apartment':
        return Icons.hotel_rounded;
      case 'museum':
      case 'gallery':
        return Icons.museum_rounded;
      case 'cinema':
      case 'theatre':
        return Icons.theaters_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'marketplace':
      case 'supermarket':
      case 'mall':
      case 'shop':
        return Icons.storefront_rounded;
      case 'viewpoint':
      case 'place':
        return Icons.place_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}
