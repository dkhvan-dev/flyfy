import 'package:flutter/material.dart';

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
          decoration: BoxDecoration(
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                right: -shortestSide * 0.4,
                bottom: -shortestSide * 0.42,
                child: Container(
                  width: smallCircle,
                  height: smallCircle,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.14),
                  ),
                ),
              ),
              PositionedDirectional(
                start: horizontalInset,
                bottom: bottomInset,
                child: Icon(
                  spec.icon,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.22),
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
                    color: Colors.white.withValues(alpha: 0.18),
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
      colors: [Color(0xFF295E54), Color(0xFF74D2AE)],
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return const ActivityCardArtSpec(
      icon: Icons.forest_rounded,
      colors: [Color(0xFF2A4B2B), Color(0xFF78C36A)],
    );
  }
  if (slug.contains('food')) {
    return const ActivityCardArtSpec(
      icon: Icons.restaurant_rounded,
      colors: [Color(0xFF66371A), Color(0xFFFFA657)],
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return const ActivityCardArtSpec(
      icon: Icons.palette_outlined,
      colors: [Color(0xFF5A3055), Color(0xFFCB84BA)],
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const ActivityCardArtSpec(
      icon: Icons.kayaking_rounded,
      colors: [Color(0xFF5F3D1F), Color(0xFFE69B4B)],
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return const ActivityCardArtSpec(
      icon: Icons.auto_stories_rounded,
      colors: [Color(0xFF443A73), Color(0xFF9A89E2)],
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return const ActivityCardArtSpec(
      icon: Icons.celebration_rounded,
      colors: [Color(0xFF5A2348), Color(0xFFE07AB8)],
    );
  }

  return const ActivityCardArtSpec(
    icon: Icons.travel_explore_rounded,
    colors: [Color(0xFF52301B), Color(0xFFCB8B50)],
  );
}

ActivityCardArtSpec activityCardArtForItem(ActivityListItemVm item) {
  final fromCategory = activityCategoryVisual(item.categorySlug);
  if (item.format.toUpperCase() == 'ONLINE') {
    return const ActivityCardArtSpec(
      icon: Icons.videocam_rounded,
      colors: [Color(0xFF1F4D8A), Color(0xFF67A8F5)],
    );
  }
  if (item.format.toUpperCase() == 'HYBRID') {
    return const ActivityCardArtSpec(
      icon: Icons.devices_rounded,
      colors: [Color(0xFF5E3E86), Color(0xFFB08CF6)],
    );
  }
  return fromCategory;
}
