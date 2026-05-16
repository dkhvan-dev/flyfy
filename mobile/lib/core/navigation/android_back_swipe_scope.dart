import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AndroidBackSwipeScope extends StatefulWidget {
  const AndroidBackSwipeScope({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<AndroidBackSwipeScope> createState() => _AndroidBackSwipeScopeState();
}

class _AndroidBackSwipeScopeState extends State<AndroidBackSwipeScope> {
  static const double _minDistance = 56;
  static const double _minVelocity = 700;

  bool _isTracking = false;
  double _distance = 0;

  bool get _supportsAndroidBackSwipe =>
      widget.enabled && defaultTargetPlatform == TargetPlatform.android;

  void _reset() {
    _isTracking = false;
    _distance = 0;
  }

  double _edgeWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width <= 393 ? 68.0 : 76.0;
  }

  void _handleStart(DragStartDetails details) {
    if (!_supportsAndroidBackSwipe || !Navigator.of(context).canPop()) {
      _reset();
      return;
    }

    _isTracking = details.localPosition.dx <= _edgeWidth(context);
    _distance = 0;
  }

  void _handleUpdate(DragUpdateDetails details) {
    if (!_isTracking) {
      return;
    }

    final delta = details.primaryDelta ?? 0;
    if (delta < 0 && _distance <= 0) {
      _reset();
      return;
    }

    _distance += delta;
  }

  void _handleEnd(DragEndDetails details) {
    final primaryVelocity = details.primaryVelocity ?? 0;
    final shouldPop = _isTracking &&
        Navigator.of(context).canPop() &&
        (_distance >= _minDistance || primaryVelocity >= _minVelocity);

    _reset();
    if (!shouldPop) {
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsAndroidBackSwipe) {
      return widget.child;
    }

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _edgeWidth(context),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleStart,
            onHorizontalDragUpdate: _handleUpdate,
            onHorizontalDragEnd: _handleEnd,
            onHorizontalDragCancel: _reset,
          ),
        ),
      ],
    );
  }
}
