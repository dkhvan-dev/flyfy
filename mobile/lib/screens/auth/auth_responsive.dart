import 'package:flutter/material.dart';

class AuthResponsiveTextScope extends StatelessWidget {
  const AuthResponsiveTextScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortSide = mediaQuery.size.shortestSide;
    final baseScale = mediaQuery.textScaler.scale(1);

    double widthScale;
    if (shortSide <= 320) {
      widthScale = 0.88;
    } else if (shortSide <= 360) {
      widthScale = 0.94;
    } else if (shortSide <= 390) {
      widthScale = 0.98;
    } else if (shortSide >= 430) {
      widthScale = 1.03;
    } else {
      widthScale = 1;
    }

    final effectiveScale = (baseScale * widthScale).clamp(0.88, 1.14);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: child,
    );
  }
}

double authUiScale(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final shortSide = mediaQuery.size.shortestSide;
  final height = mediaQuery.size.height;

  double scale;
  if (shortSide <= 320) {
    scale = 0.86;
  } else if (shortSide <= 360) {
    scale = 0.92;
  } else if (shortSide <= 390) {
    scale = 0.97;
  } else if (shortSide >= 430) {
    scale = 1.03;
  } else {
    scale = 1;
  }

  if (height < 700) {
    scale *= 0.94;
  } else if (height > 920) {
    scale *= 1.02;
  }

  return scale.clamp(0.84, 1.08);
}

double authScaled(
  BuildContext context,
  double value, {
  double? min,
  double? max,
}) {
  final scaled = value * authUiScale(context);
  if (min == null && max == null) {
    return scaled;
  }
  return scaled.clamp(min ?? scaled, max ?? scaled);
}
