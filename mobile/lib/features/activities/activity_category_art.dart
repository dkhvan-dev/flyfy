import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import 'models/activity_list_item_vm.dart';

class ActivityCardArtSpec {
  const ActivityCardArtSpec({
    required this.icon,
    this.tone = ActivityCardArtTone.general,
    List<Color>? colors,
  }) : _customColors = colors;

  final IconData icon;
  final ActivityCardArtTone tone;
  final List<Color>? _customColors;

  List<Color> colorsFor(BuildContext context) {
    final customColors = _customColors;
    if (customColors != null && customColors.isNotEmpty) {
      return customColors;
    }
    final colors = AppDesignSystem.colorsFor(context);
    return tone.gradient(colors);
  }
}

enum ActivityCardArtTone {
  wellness,
  nature,
  food,
  culture,
  sport,
  learning,
  night,
  online,
  hybrid,
  general,
}

extension ActivityCardArtToneX on ActivityCardArtTone {
  List<Color> gradient(AppColors colors) {
    return switch (this) {
      ActivityCardArtTone.wellness => [
        colors.surfaceTeal,
        colors.secondarySoft,
      ],
      ActivityCardArtTone.nature => [
        colors.secondaryContainer,
        colors.secondary,
      ],
      ActivityCardArtTone.food => [colors.surfaceWarm, colors.primarySoft],
      ActivityCardArtTone.culture => [
        colors.primaryContainer,
        colors.secondaryContainer,
      ],
      ActivityCardArtTone.sport => [colors.primaryContainer, colors.primary],
      ActivityCardArtTone.learning => [
        colors.surfaceRaised,
        colors.secondaryContainer,
      ],
      ActivityCardArtTone.night => [
        colors.backgroundDeep,
        colors.primaryContainer,
      ],
      ActivityCardArtTone.online => [colors.surfaceTeal, colors.secondary],
      ActivityCardArtTone.hybrid => [
        colors.surfaceHigh,
        colors.primaryContainer,
      ],
      ActivityCardArtTone.general => [colors.surfaceWarm, colors.primary],
    };
  }
}

class ActivityDecorativeCover extends StatelessWidget {
  const ActivityDecorativeCover({super.key, required this.spec, this.imageUrl});

  final ActivityCardArtSpec spec;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim() ?? '';
    if (normalizedImageUrl.isNotEmpty) {
      return Image.network(
        normalizedImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            ActivityDecorativeCoverFallback(spec: spec),
      );
    }

    return ActivityDecorativeCoverFallback(spec: spec);
  }
}

class ActivityDecorativeCoverFallback extends StatelessWidget {
  const ActivityDecorativeCoverFallback({super.key, required this.spec});

  final ActivityCardArtSpec spec;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decorativeForeground = isDark ? colors.white : colors.textPrimary;
    final sourceColors = spec.colorsFor(context);
    final backgroundColors = isDark
        ? sourceColors
        : [
            Color.alphaBlend(
              sourceColors.first.withValues(alpha: 0.16),
              colors.surface,
            ),
            Color.alphaBlend(
              sourceColors.last.withValues(alpha: 0.10),
              colors.surfaceHigh,
            ),
          ];
    final topCircleColor = isDark
        ? colors.white.withValues(alpha: 0.12)
        : colors.secondaryContainer.withValues(alpha: 0.28);
    final bottomCircleColor = isDark
        ? colors.black.withValues(alpha: 0.14)
        : colors.secondary.withValues(alpha: 0.10);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackSide = MediaQuery.sizeOf(context).shortestSide * 0.28;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackSide;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : fallbackSide;
        final shortestSide = width < height ? width : height;
        final artScale = shortestSide.clamp(1.0, 180.0) / 108;
        final largeCircle = shortestSide * 1.34;
        final smallCircle = shortestSide * 1.5;
        final iconSize = shortestSide * 0.42 * artScale.clamp(0.72, 1.0);
        final arrowSize = shortestSide * 0.22 * artScale.clamp(0.78, 1.0);
        final horizontalInset = shortestSide * 0.12;
        final bottomInset = shortestSide * 0.1;

        return DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: backgroundColors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: -shortestSide * 0.28,
                top: -shortestSide * 0.3,
                child: Container(
                  width: largeCircle,
                  height: largeCircle,
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: topCircleColor,
                  ),
                ),
              ),
              Positioned(
                right: -shortestSide * 0.4,
                bottom: -shortestSide * 0.42,
                child: Container(
                  width: smallCircle,
                  height: smallCircle,
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: bottomCircleColor,
                  ),
                ),
              ),
              PositionedDirectional(
                start: horizontalInset,
                bottom: bottomInset,
                child: Icon(
                  spec.icon,
                  size: iconSize,
                  color: decorativeForeground.withValues(
                    alpha: isDark ? 0.22 : 0.18,
                  ),
                ),
              ),
              PositionedDirectional(
                end: horizontalInset,
                bottom: bottomInset,
                child: Transform.rotate(
                  angle: -0.18,
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: arrowSize,
                    color: decorativeForeground.withValues(
                      alpha: isDark ? 0.18 : 0.14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

ActivityCardArtSpec activityCategoryVisual(String rawSlug) {
  final slug = rawSlug.trim().toLowerCase();
  if (slug.contains('wellness') || slug.contains('health')) {
    return const ActivityCardArtSpec(
      icon: Icons.spa_rounded,
      tone: ActivityCardArtTone.wellness,
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return const ActivityCardArtSpec(
      icon: Icons.forest_rounded,
      tone: ActivityCardArtTone.nature,
    );
  }
  if (slug.contains('food')) {
    return const ActivityCardArtSpec(
      icon: Icons.restaurant_rounded,
      tone: ActivityCardArtTone.food,
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return const ActivityCardArtSpec(
      icon: Icons.palette_outlined,
      tone: ActivityCardArtTone.culture,
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const ActivityCardArtSpec(
      icon: Icons.kayaking_rounded,
      tone: ActivityCardArtTone.sport,
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return const ActivityCardArtSpec(
      icon: Icons.auto_stories_rounded,
      tone: ActivityCardArtTone.learning,
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return const ActivityCardArtSpec(
      icon: Icons.celebration_rounded,
      tone: ActivityCardArtTone.night,
    );
  }

  return const ActivityCardArtSpec(
    icon: Icons.travel_explore_rounded,
    tone: ActivityCardArtTone.general,
  );
}

ActivityCardArtSpec activityCardArtForItem(ActivityListItemVm item) {
  final fromCategory = activityCategoryVisual(item.categorySlug);
  if (item.format.toUpperCase() == 'ONLINE') {
    return const ActivityCardArtSpec(
      icon: Icons.videocam_rounded,
      tone: ActivityCardArtTone.online,
    );
  }
  if (item.format.toUpperCase() == 'HYBRID') {
    return const ActivityCardArtSpec(
      icon: Icons.devices_rounded,
      tone: ActivityCardArtTone.hybrid,
    );
  }
  return fromCategory;
}
