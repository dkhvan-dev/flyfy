import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

const Color profileBgTop = AppPalette.warmInk47;
const Color profileBgBottom = AppPalette.warmInk24;
const Color profileSurface = AppPalette.warmSurface09;
const Color profileSurfaceSoft = AppPalette.warmSurface41;
const Color profileSurfaceMuted = AppPalette.warmSurface76;
const Color profileBorder = AppPalette.borderStrong;
const Color profileBorderSoft = AppPalette.borderSoft;
const Color profileTextSoft = AppPalette.orangeLight16;
const Color profileTextMuted = AppPalette.orangeSoft01;
const Color profileDisabled = AppPalette.textDisabled;

class ProfileResponsiveScope extends StatelessWidget {
  const ProfileResponsiveScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
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
      ? AppPalette.transparent
      : AppPalette.primary.withValues(alpha: highlighted ? 0.18 : 0.1);

  return AppBoxDecoration(
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
              AppPalette.white.withValues(alpha: 0.03),
              AppPalette.white.withValues(alpha: 0.015),
            ],
    ),
    borderRadius: AppBorderRadius.circular(
      radius ?? profileScaled(context, 22, min: 18, max: 28),
    ),
    border: Border.all(
      color: disabled
          ? profileBorderSoft
          : highlighted
          ? profileBorder
          : AppPalette.white.withValues(alpha: 0.04),
    ),
    boxShadow: [
      BoxShadow(
        color: AppPalette.black.withValues(alpha: 0.22),
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
      color: AppPalette.white.withValues(alpha: 0.04),
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
            color: disabled ? profileDisabled : AppPalette.textPrimary,
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
                  padding: AppEdgeInsets.only(
                    bottom: profileScaled(context, 6, min: 4, max: 6),
                  ),
                  child: Text(
                    kicker!,
                    style: AppTextStyle(
                      color: profileTextSoft,
                      fontSize: profileScaled(context, 11, min: 10, max: 11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              Text(
                title,
                style: AppTextStyle(
                  color: AppPalette.textPrimary,
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
      decoration: const AppBoxDecoration(
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
              color: AppPalette.primary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 220,
            left: -100,
            child: _GlowOrb(
              size: profileScaled(context, 240, min: 160, max: 260),
              color: AppPalette.primary.withValues(alpha: 0.06),
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
        decoration: AppBoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
