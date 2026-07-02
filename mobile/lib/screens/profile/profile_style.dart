import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

const Color profileBgTop = AppPalette.backgroundDeep;
const Color profileBgBottom = AppPalette.background;
const Color profileSurface = AppPalette.surface;
const Color profileSurfaceSoft = AppPalette.surfaceRaised;
const Color profileSurfaceMuted = AppPalette.surfaceHigh;
const Color profileBorder = AppPalette.border;
const Color profileBorderSoft = AppPalette.borderSoft;
const Color profileTextSoft = AppPalette.primary;
const Color profileTextMuted = AppPalette.textSecondary;
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
  final colors = AppDesignSystem.colorsFor(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final glowColor = disabled
      ? colors.transparent
      : colors.primary.withValues(alpha: highlighted ? 0.18 : 0.1);

  return AppBoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: disabled
          ? [
              colors.surfaceHigh.withValues(alpha: 0.66),
              colors.surface.withValues(alpha: 0.78),
            ]
          : highlighted
          ? [
              colors.surfaceRaised.withValues(alpha: 0.98),
              colors.surface.withValues(alpha: 0.96),
            ]
          : [
              colors.surface.withValues(alpha: 0.98),
              colors.surfaceHigh.withValues(alpha: 0.72),
            ],
    ),
    borderRadius: AppBorderRadius.circular(
      radius ?? profileScaled(context, 22, min: 18, max: 28),
    ),
    border: Border.all(
      color: disabled
          ? colors.borderSoft
          : highlighted
          ? colors.border
          : colors.borderSoft,
    ),
    boxShadow: [
      if (isDark)
        BoxShadow(
          color: colors.black.withValues(alpha: 0.22),
          blurRadius: profileScaled(context, 24, min: 16, max: 28),
          offset: Offset(0, profileScaled(context, 10, min: 6, max: 12)),
        ),
      if (isDark && !disabled)
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
    final colors = AppDesignSystem.colorsFor(context);
    final size = profileScaled(context, 38, min: 34, max: 40);
    final iconSize = profileScaled(context, 20, min: 18, max: 20);

    return Material(
      color: colors.surfaceHigh.withValues(alpha: 0.82),
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
            color: disabled ? colors.textDisabled : colors.textPrimary,
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
    final colors = AppDesignSystem.colorsFor(context);

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
                      color: colors.primary,
                      fontSize: profileScaled(context, 11, min: 10, max: 11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              Text(
                title,
                style: AppTextStyle(
                  color: colors.textPrimary,
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
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.screenGradientColors,
        ),
      ),
      child: child,
    );
  }
}
