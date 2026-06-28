import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import 'models/activity_list_item_vm.dart';

class ActivityCardArtSpec {
  const ActivityCardArtSpec({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;
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
              colors: spec.colors,
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
                    color: AppPalette.white.withValues(alpha: 0.12),
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
                    color: AppPalette.black.withValues(alpha: 0.14),
                  ),
                ),
              ),
              PositionedDirectional(
                start: horizontalInset,
                bottom: bottomInset,
                child: Icon(
                  spec.icon,
                  size: iconSize,
                  color: AppPalette.white.withValues(alpha: 0.22),
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
                    color: AppPalette.white.withValues(alpha: 0.18),
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
      colors: [AppPalette.tealSurfaceHigh06, AppPalette.tealSoft04],
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return const ActivityCardArtSpec(
      icon: Icons.forest_rounded,
      colors: [AppPalette.greenSurfaceHigh13, AppPalette.greenSoft03],
    );
  }
  if (slug.contains('food')) {
    return const ActivityCardArtSpec(
      icon: Icons.restaurant_rounded,
      colors: [AppPalette.warmSurfaceHigh12, AppPalette.orangeSoft44],
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return const ActivityCardArtSpec(
      icon: Icons.palette_outlined,
      colors: [AppPalette.pinkSurfaceHigh02, AppPalette.pinkSoft02],
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const ActivityCardArtSpec(
      icon: Icons.kayaking_rounded,
      colors: [AppPalette.warmSurfaceHigh11, AppPalette.orangeSoft34],
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return const ActivityCardArtSpec(
      icon: Icons.auto_stories_rounded,
      colors: [AppPalette.blueSurfaceHigh30, AppPalette.blueSoft15],
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return const ActivityCardArtSpec(
      icon: Icons.celebration_rounded,
      colors: [AppPalette.pinkSurfaceHigh01, AppPalette.pinkSoft04],
    );
  }

  return const ActivityCardArtSpec(
    icon: Icons.travel_explore_rounded,
    colors: [AppPalette.warmSurface90, AppPalette.orangeMuted05],
  );
}

ActivityCardArtSpec activityCardArtForItem(ActivityListItemVm item) {
  final fromCategory = activityCategoryVisual(item.categorySlug);
  if (item.format.toUpperCase() == 'ONLINE') {
    return const ActivityCardArtSpec(
      icon: Icons.videocam_rounded,
      colors: [AppPalette.blueSurfaceHigh18, AppPalette.blueSoft07],
    );
  }
  if (item.format.toUpperCase() == 'HYBRID') {
    return const ActivityCardArtSpec(
      icon: Icons.devices_rounded,
      colors: [AppPalette.violetMuted01, AppPalette.violetLight02],
    );
  }
  return fromCategory;
}
