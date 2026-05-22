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
    final largeCircle = _activityArtScaled(context, 150, min: 112, max: 162);
    final smallCircle = _activityArtScaled(context, 170, min: 124, max: 182);
    final iconSize = _activityArtScaled(context, 66, min: 50, max: 70);
    final arrowSize = _activityArtScaled(context, 34, min: 26, max: 36);
    final horizontalInset = _activityArtScaled(context, 26, min: 18, max: 28);
    final bottomInset = _activityArtScaled(context, 14, min: 10, max: 16);

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
            left: -_activityArtScaled(context, 32, min: 20, max: 34),
            top: -_activityArtScaled(context, 34, min: 22, max: 36),
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
            right: -_activityArtScaled(context, 44, min: 28, max: 46),
            bottom: -_activityArtScaled(context, 48, min: 30, max: 50),
            child: Container(
              width: smallCircle,
              height: smallCircle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            left: horizontalInset,
            right: horizontalInset,
            bottom: bottomInset,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  spec.icon,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                Transform.rotate(
                  angle: -0.18,
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: arrowSize,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

double _activityArtScaled(
  BuildContext context,
  double value, {
  double? min,
  double? max,
}) {
  final scaled = value * _activityArtUiScale(context);
  if (min == null && max == null) {
    return scaled;
  }
  return scaled.clamp(min ?? scaled, max ?? scaled);
}

double _activityArtUiScale(BuildContext context) {
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
