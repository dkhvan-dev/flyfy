import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/device/device_context_service.dart';
import '../../core/ui/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialTarget});

  final MapTarget? initialTarget;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _fallbackCenter = LatLng(43.238949, 76.889709);
  static const double _defaultZoom = 14.6;
  static const int _searchRadiusMeters = 1800;

  final MapController _mapController = MapController();
  final DeviceContextService _deviceContextService =
      const DeviceContextService();
  final _NearbyPlacesApi _placesApi = _NearbyPlacesApi();
  final Distance _distance = const Distance();

  Timer? _reloadDebounce;
  Timer? _placesRetryDebounce;

  bool _bootstrapping = true;
  bool _loadingPlaces = false;
  bool _locatingUser = false;
  bool _mapReady = false;
  String? _locationIssueCode;
  String? _placesErrorMessage;
  String? _locationLabel;
  LatLng _mapCenter = _fallbackCenter;
  LatLng? _userLocation;
  _LocalPlace? _targetPlace;
  List<_LocalPlace> _places = const [];
  _LocalPlace? _selectedPlace;
  int _autoPlacesRetryCount = 0;

  @override
  void initState() {
    super.initState();
    final target = widget.initialTarget;
    if (target != null) {
      unawaited(_bootstrapTarget(target));
    } else {
      unawaited(_bootstrap());
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _placesRetryDebounce?.cancel();
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

  Future<void> _bootstrapTarget(MapTarget target) async {
    _autoPlacesRetryCount = 0;
    _placesRetryDebounce?.cancel();

    final targetPlace = _LocalPlace(
      id: 'target:${target.latitude}:${target.longitude}',
      title: target.title,
      categoryValue: 'attraction',
      categoryLabel: target.subtitle?.trim().isNotEmpty == true
          ? target.subtitle!.trim()
          : target.title,
      point: target.point,
      distanceMeters: 0,
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
    await _loadPlaces(target.point);
  }

  Future<void> _recenterToUser() async {
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
      await _loadPlaces(center, selectFirst: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationIssueCode = error.toString();
      });
      _showSnack(_resolveLocationIssueMessage(AppLocalizations.of(context)!));
    } finally {
      if (mounted) {
        setState(() {
          _locatingUser = false;
        });
      }
    }
  }

  void _moveMap(LatLng center) {
    if (!_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _moveMap(center);
      });
      return;
    }

    _mapController.move(center, _defaultZoom);
  }

  Future<void> _loadPlaces(LatLng center, {bool selectFirst = false}) async {
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

  void _handleMapPositionChanged(MapCamera camera, bool hasGesture) {
    _mapCenter = camera.center;
    if (!hasGesture) {
      return;
    }

    _placesRetryDebounce?.cancel();
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      unawaited(_loadPlaces(camera.center));
    });
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

    if (animate && _mapReady) {
      _mapController.move(place.point, 16.2);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final placesCountLabel = l10n.mapPlacesCount(_places.length);

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
                      ? 102
                      : narrowScreen
                          ? 130
                          : compactHeight
                              ? 114
                              : 124,
                  min: 96,
                  max: 138,
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
                                  l10n.homeNavMap,
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
                                  _locationLabel ??
                                      _resolveLocationIssueMessage(l10n),
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
                          _MapInfoChip(
                            icon: Icons.place_outlined,
                            label: placesCountLabel,
                          ),
                          _MapInfoChip(
                            icon: Icons.storefront_outlined,
                            label: l10n.mapNearbyPlacesLabel,
                          ),
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
                                    FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: _mapCenter,
                                        initialZoom: _defaultZoom,
                                        backgroundColor: const Color(
                                          0xFFB3A28D,
                                        ),
                                        onMapReady: () {
                                          _mapReady = true;
                                          _moveMap(_mapCenter);
                                        },
                                        onPositionChanged:
                                            _handleMapPositionChanged,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'kz.inflap',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            if (_userLocation != null)
                                              Marker(
                                                point: _userLocation!,
                                                width: _mapScaled(
                                                  context,
                                                  32,
                                                  min: 26,
                                                  max: 34,
                                                ),
                                                height: _mapScaled(
                                                  context,
                                                  32,
                                                  min: 26,
                                                  max: 34,
                                                ),
                                                child:
                                                    const _UserLocationMarker(),
                                              ),
                                            if (_targetPlace != null)
                                              Marker(
                                                point: _targetPlace!.point,
                                                width: _mapScaled(
                                                  context,
                                                  58,
                                                  min: 48,
                                                  max: 60,
                                                ),
                                                height: _mapScaled(
                                                  context,
                                                  68,
                                                  min: 56,
                                                  max: 70,
                                                ),
                                                alignment: Alignment.topCenter,
                                                child: _PlaceMarker(
                                                  place: _targetPlace!,
                                                  selected: selectedPlace?.id ==
                                                      _targetPlace!.id,
                                                  onTap: () => _selectPlace(
                                                    _targetPlace!,
                                                  ),
                                                ),
                                              ),
                                            for (final place in _places)
                                              Marker(
                                                point: place.point,
                                                width: _mapScaled(
                                                  context,
                                                  52,
                                                  min: 42,
                                                  max: 54,
                                                ),
                                                height: _mapScaled(
                                                  context,
                                                  62,
                                                  min: 50,
                                                  max: 64,
                                                ),
                                                alignment: Alignment.topCenter,
                                                child: _PlaceMarker(
                                                  place: place,
                                                  selected: selectedPlace?.id ==
                                                      place.id,
                                                  onTap: () =>
                                                      _selectPlace(place),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
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
                                                    key:
                                                        const ValueKey('error'),
                                                    icon: Icons
                                                        .error_outline_rounded,
                                                    label: l10n
                                                        .mapPlacesLoadFailed,
                                                    actionLabel:
                                                        l10n.retryButton,
                                                    onActionTap: () =>
                                                        _loadPlaces(
                                                      _mapCenter,
                                                      selectFirst: true,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                      ),
                                    ),
                                    if (!_bootstrapping &&
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
                              fit: FlexFit.loose,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: contentWidth,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_places.isNotEmpty) ...[
                                        SizedBox(
                                          height: previewRailHeight,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: _places.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(
                                              width: _mapScaled(
                                                context,
                                                12,
                                                min: 10,
                                                max: 12,
                                              ),
                                            ),
                                            itemBuilder: (context, index) {
                                              final place = _places[index];
                                              return _PlacePreviewCard(
                                                place: place,
                                                selected: selectedPlace?.id ==
                                                    place.id,
                                                distanceLabel: _formatDistance(
                                                  place,
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
                                                key: const ValueKey('hint'),
                                                label: l10n.mapTapPlaceHint,
                                              )
                                            : _SelectedPlaceCard(
                                                key: ValueKey(selectedPlace.id),
                                                place: selectedPlace,
                                                distanceLabel: _formatDistance(
                                                  selectedPlace,
                                                ),
                                                copyLabel:
                                                    l10n.mapCopyPlaceLink,
                                                onCopyTap: () => _copyPlaceLink(
                                                  selectedPlace,
                                                ),
                                              ),
                                      ),
                                    ],
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

  String _formatDistance(_LocalPlace place) {
    final distanceMeters = _distance.as(
      LengthUnit.Meter,
      _userLocation ?? _mapCenter,
      place.point,
    );

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
    final horizontalPadding = _mapScaled(context, 14, min: 10, max: 14);
    final verticalPadding = _mapScaled(context, 9, min: 7, max: 9);
    final iconSize = _mapScaled(context, 16, min: 14, max: 16);
    final labelSpacing = _mapScaled(context, 8, min: 6, max: 8);

    return Container(
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
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: _mapScaled(context, 13, min: 11.5, max: 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
              color: selected ? AppColors.accent : const Color(0xFFF6E5D4),
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
            child: Icon(
              place.icon,
              size: _mapScaled(context, 17, min: 14, max: 17),
              color: selected ? AppColors.textPrimary : const Color(0xFF6A3D0B),
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
          final compactCard = screenWidth < 380 ||
              constraints.maxHeight <
                  _mapScaled(context, 118, min: 112, max: 118) ||
              textScale > 1.02;
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
                        const Spacer(),
                        Text(
                          distanceLabel,
                          style: TextStyle(
                            color: selected
                                ? AppColors.textPrimary.withValues(alpha: 0.78)
                                : const Color(0xB3FFF0E0),
                            fontSize: _mapScaled(context, 12, min: 11, max: 12),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: titleGap),
                    Text(
                      place.title,
                      maxLines: compactCard ? 1 : 2,
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
    required this.copyLabel,
    required this.onCopyTap,
  });

  final _LocalPlace place;
  final String distanceLabel;
  final String copyLabel;
  final VoidCallback onCopyTap;

  @override
  Widget build(BuildContext context) {
    final radius = _mapScaled(context, 26, min: 22, max: 26);
    final buttonHeight = _mapScaled(context, 46, min: 40, max: 46);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

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
          final stacked = constraints.maxWidth < 360 || textScale > 1.06;

          final button = FilledButton.tonal(
            onPressed: onCopyTap,
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
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: _mapScaled(context, 16, min: 14, max: 16),
                ),
                SizedBox(width: _mapScaled(context, 8, min: 6, max: 8)),
                Flexible(
                  child: Text(copyLabel, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );

          final info = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: _mapScaled(context, 16, min: 14, max: 16),
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                SizedBox(height: _mapScaled(context, 6, min: 4, max: 6)),
                Text(
                  '${place.categoryLabel} · $distanceLabel',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xB3FFF0E0),
                    fontSize: _mapScaled(context, 13, min: 12, max: 13),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: _mapScaled(context, 48, min: 40, max: 48),
                      height: _mapScaled(context, 48, min: 40, max: 48),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.16),
                      ),
                      child: Icon(
                        place.icon,
                        color: AppColors.accent,
                        size: _mapScaled(context, 22, min: 18, max: 22),
                      ),
                    ),
                    SizedBox(width: _mapScaled(context, 12, min: 10, max: 12)),
                    info,
                  ],
                ),
                SizedBox(height: _mapScaled(context, 14, min: 10, max: 14)),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: _mapScaled(context, 48, min: 42, max: 48),
                height: _mapScaled(context, 48, min: 42, max: 48),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.16),
                ),
                child: Icon(
                  place.icon,
                  color: AppColors.accent,
                  size: _mapScaled(context, 22, min: 18, max: 22),
                ),
              ),
              SizedBox(width: _mapScaled(context, 14, min: 10, max: 14)),
              info,
              SizedBox(width: _mapScaled(context, 12, min: 8, max: 12)),
              button,
            ],
          );
        },
      ),
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
          resultLimit: 40,
        ),
      for (final endpoint in _publicEndpoints)
        _NearbyPlacesRequest(
          endpoint: endpoint,
          radiusMeters: (radiusMeters * 0.66).round(),
          resultLimit: 28,
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
  node["tourism"~"hotel|museum|attraction|viewpoint|gallery|guest_house|apartment"](around:$radiusMeters,${center.latitude},${center.longitude});
  node["leisure"~"park|fitness_centre|sports_centre"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["amenity"~"cafe|restaurant|fast_food|bar|pub|pharmacy|hospital|clinic|bank|atm|fuel|cinema|theatre|library|marketplace"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["shop"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["tourism"~"hotel|museum|attraction|viewpoint|gallery|guest_house|apartment"](around:$radiusMeters,${center.latitude},${center.longitude});
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
      final lat = (element['lat'] as num?)?.toDouble() ??
          (element['center'] as Map?)?['lat'] as num?;
      final lon = (element['lon'] as num?)?.toDouble() ??
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
  });

  final String id;
  final String title;
  final String categoryValue;
  final String categoryLabel;
  final LatLng point;
  final double distanceMeters;

  String get linkUrl =>
      'https://www.openstreetmap.org/?mlat=${point.latitude}&mlon=${point.longitude}#map=17/${point.latitude}/${point.longitude}';

  IconData get icon {
    switch (categoryValue.toLowerCase()) {
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
      case 'attraction':
        return Icons.place_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}
