import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';

const Color profileBgTop = Color(0xFF1C1007);
const Color profileBgBottom = Color(0xFF170C04);
const Color profileSurface = Color(0xFF2A180D);
const Color profileSurfaceSoft = Color(0xFF322013);
const Color profileSurfaceMuted = Color(0xFF433124);
const Color profileBorder = Color(0x33FF9800);
const Color profileBorderSoft = Color(0x12FFFFFF);
const Color profileTextSoft = Color(0xFFD8CABC);
const Color profileTextMuted = Color(0xFFA59282);
const Color profileDisabled = Color(0xFF756252);

class ProfileResponsiveScope extends StatelessWidget {
  const ProfileResponsiveScope({super.key, required this.child});

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
      widthScale = 0.93;
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

double profileUiScale(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final shortSide = mediaQuery.size.shortestSide;
  final height = mediaQuery.size.height;

  double scale;
  if (shortSide <= 320) {
    scale = 0.84;
  } else if (shortSide <= 360) {
    scale = 0.91;
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

  return scale.clamp(0.82, 1.08);
}

double profileScaled(
  BuildContext context,
  double value, {
  double? min,
  double? max,
}) {
  final scaled = value * profileUiScale(context);
  return scaled.clamp(min ?? scaled, max ?? scaled);
}

BoxDecoration profileCardDecoration(
  BuildContext context, {
  bool highlighted = false,
  bool disabled = false,
  double? radius,
}) {
  final glowColor = disabled
      ? Colors.transparent
      : AppColors.accent.withValues(alpha: highlighted ? 0.18 : 0.1);

  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: disabled
          ? [
              profileSurfaceMuted.withValues(alpha: 0.66),
              profileSurface.withValues(alpha: 0.78),
            ]
          : highlighted
          ? [
              profileSurfaceSoft.withValues(alpha: 0.98),
              profileSurface.withValues(alpha: 0.96),
            ]
          : [
              Colors.white.withValues(alpha: 0.03),
              Colors.white.withValues(alpha: 0.015),
            ],
    ),
    borderRadius: BorderRadius.circular(
      radius ?? profileScaled(context, 22, min: 18, max: 28),
    ),
    border: Border.all(
      color: disabled
          ? profileBorderSoft
          : highlighted
          ? profileBorder
          : Colors.white.withValues(alpha: 0.04),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: profileScaled(context, 24, min: 16, max: 28),
        offset: Offset(0, profileScaled(context, 10, min: 6, max: 12)),
      ),
      if (!disabled)
        BoxShadow(
          color: glowColor,
          blurRadius: profileScaled(context, 20, min: 12, max: 24),
          offset: Offset(0, profileScaled(context, 6, min: 4, max: 8)),
        ),
    ],
  );
}

class ProfileTopIconButton extends StatelessWidget {
  const ProfileTopIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final size = profileScaled(context, 38, min: 34, max: 40);
    final iconSize = profileScaled(context, 20, min: 18, max: 20);

    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: disabled ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: disabled ? profileDisabled : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class ProfileSectionHeading extends StatelessWidget {
  const ProfileSectionHeading({
    super.key,
    required this.title,
    this.kicker,
    this.trailing,
  });

  final String title;
  final String? kicker;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((kicker ?? '').trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: profileScaled(context, 6, min: 4, max: 6),
                  ),
                  child: Text(
                    kicker!,
                    style: TextStyle(
                      color: profileTextSoft,
                      fontSize: profileScaled(context, 11, min: 10, max: 11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: profileScaled(context, 18, min: 16, max: 22),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class ProfileGlassBackground extends StatelessWidget {
  const ProfileGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [profileBgTop, profileBgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(
              size: profileScaled(context, 280, min: 200, max: 320),
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 220,
            left: -100,
            child: _GlowOrb(
              size: profileScaled(context, 240, min: 160, max: 260),
              color: AppColors.accent.withValues(alpha: 0.06),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
