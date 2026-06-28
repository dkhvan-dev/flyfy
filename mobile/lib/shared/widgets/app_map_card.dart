import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:maplibre/maplibre.dart' hide LengthUnit;

import '../../core/config/app_config.dart';
import '../map/app_map_gesture_recognizers.dart';
import 'app_map_attribution.dart';

class AppMapCard extends StatefulWidget {
  const AppMapCard({
    super.key,
    required this.target,
    required this.hasMarker,
    this.onTap,
    this.height,
    this.initialZoom = 15,
    this.fallbackZoom = 12,
    this.borderRadius = 24,
    this.gesturesEnabled = true,
    this.nativeMapEnabled = true,
    this.overlay,
  });

  final LatLng target;
  final bool hasMarker;
  final ValueChanged<LatLng>? onTap;
  final double? height;
  final double initialZoom;
  final double fallbackZoom;
  final double borderRadius;
  final bool gesturesEnabled;
  final bool nativeMapEnabled;
  final Widget? overlay;

  @override
  State<AppMapCard> createState() => _AppMapCardState();
}

class _AppMapCardState extends State<AppMapCard> {
  MapController? _mapController;
  bool _mapReady = false;
  int _mapViewGeneration = 0;

  @override
  void didUpdateWidget(covariant AppMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nativeMapEnabled != widget.nativeMapEnabled) {
      _mapReady = false;
      _mapController = null;
      if (widget.nativeMapEnabled) {
        _mapViewGeneration += 1;
      }
    }
    if (oldWidget.target != widget.target ||
        oldWidget.hasMarker != widget.hasMarker) {
      _moveMap();
    }
  }

  void _moveMap() {
    final controller = _mapController;
    if (!widget.nativeMapEnabled || !_mapReady || controller == null) {
      return;
    }
    unawaited(
      controller.animateCamera(
        center: _toGeographic(widget.target),
        zoom: widget.hasMarker ? widget.initialZoom : widget.fallbackZoom,
        nativeDuration: const Duration(milliseconds: 240),
        webMaxDuration: const Duration(milliseconds: 240),
      ),
    );
  }

  void _handleMapEvent(MapEvent event) {
    if (!mounted || !widget.nativeMapEnabled) {
      return;
    }
    if (event case MapEventClick(point: final point)) {
      widget.onTap?.call(LatLng(point.lat.toDouble(), point.lon.toDouble()));
    }
  }

  @override
  void dispose() {
    _mapReady = false;
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = widget.height ?? (width <= 393 ? 168.0 : 178.0);
    final point = _toGeographic(widget.target);
    if (!widget.nativeMapEnabled || !_canRenderMapLibre) {
      return _AppMapFallbackCard(
        height: height,
        borderRadius: widget.borderRadius,
        hasMarker: widget.hasMarker,
        overlay: widget.overlay,
      );
    }

    return ClipRRect(
      borderRadius: AppBorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: AppPalette.orangeSoft05,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MapLibreMap(
                key: ValueKey('app-map-card-$_mapViewGeneration'),
                gestureRecognizers: widget.gesturesEnabled
                    ? appMapGestureRecognizers()
                    : null,
                options: MapOptions(
                  initStyle: AppConfig.mapStyleUrl,
                  initCenter: point,
                  initZoom: widget.hasMarker
                      ? widget.initialZoom
                      : widget.fallbackZoom,
                  gestures: widget.gesturesEnabled
                      ? const MapGestures.all()
                      : const MapGestures.none(),
                  androidForegroundLoadColor: AppPalette.orangeSoft05,
                ),
                onMapCreated: (controller) {
                  if (!mounted || !widget.nativeMapEnabled) {
                    return;
                  }
                  _mapController = controller;
                },
                onStyleLoaded: (_) {
                  if (!mounted || !widget.nativeMapEnabled) {
                    return;
                  }
                  _mapReady = true;
                  _moveMap();
                },
                onEvent: _handleMapEvent,
                children: [
                  WidgetLayer(
                    markers: [
                      if (widget.hasMarker)
                        Marker(
                          point: point,
                          size: const Size(54, 64),
                          alignment: Alignment.topCenter,
                          child: const _AppMapPinMarker(),
                        ),
                    ],
                  ),
                  const AppMapAttribution(alignment: Alignment.bottomRight),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: AppBoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppPalette.warmInk37.withValues(alpha: 0.10),
                          AppPalette.transparent,
                          AppPalette.warmInk37.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.overlay != null) widget.overlay!,
            ],
          ),
        ),
      ),
    );
  }

  Geographic _toGeographic(LatLng point) {
    return Geographic(lon: point.longitude, lat: point.latitude);
  }

  bool get _canRenderMapLibre {
    if (kIsWeb) {
      return true;
    }
    return Platform.isAndroid || Platform.isIOS;
  }
}

class _AppMapFallbackCard extends StatelessWidget {
  const _AppMapFallbackCard({
    required this.height,
    required this.borderRadius,
    required this.hasMarker,
    this.overlay,
  });

  final double height;
  final double borderRadius;
  final bool hasMarker;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppBorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppPalette.orangeSoft09,
                    AppPalette.amberLight01,
                    AppPalette.greenSoft07,
                  ],
                ),
              ),
            ),
            CustomPaint(painter: const _FallbackMapPainter()),
            if (hasMarker) const Center(child: _AppMapPinMarker()),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

class _FallbackMapPainter extends CustomPainter {
  const _FallbackMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppPalette.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final parkPaint = Paint()
      ..color = AppPalette.greenMuted12.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final waterPaint = Paint()
      ..color = AppPalette.blueSoft13.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.06,
          size.height * 0.08,
          size.width * 0.36,
          size.height * 0.34,
        ),
        const AppRadiusValue.circular(18),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.62,
          size.height * 0.46,
          size.width * 0.30,
          size.height * 0.28,
        ),
        const AppRadiusValue.circular(16),
      ),
      waterPaint,
    );

    final mainRoad = Path()
      ..moveTo(-8, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.46,
        size.width + 8,
        size.height * 0.58,
      );
    canvas.drawPath(mainRoad, roadPaint);

    final sideRoad = Path()
      ..moveTo(size.width * 0.18, -8)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.72,
        size.height * 0.30,
        size.width * 0.82,
        size.height + 8,
      );
    canvas.drawPath(sideRoad, roadPaint..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppMapPinMarker extends StatelessWidget {
  const _AppMapPinMarker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppBoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.primary,
              border: Border.all(color: AppPalette.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.primary.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.location_on_rounded,
                color: AppPalette.white,
                size: 26,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: AppBoxDecoration(
              color: AppPalette.primary,
              border: Border.all(color: AppPalette.white, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
