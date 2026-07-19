import 'package:flutter/material.dart';

import '../../../../core/ui/app_design_system.dart';

class SavedCoverThumbnail extends StatelessWidget {
  const SavedCoverThumbnail({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.extent = AppSizes.avatarLg,
    this.selected = false,
    this.imageKey,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final double extent;
  final bool selected;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final normalizedImageUrl = _normalizedHttpUrl(imageUrl);
    final fallback = _SavedCoverFallback(
      icon: fallbackIcon,
      selected: selected,
    );
    final pixelExtent = (extent * MediaQuery.devicePixelRatioOf(context))
        .round();

    return SizedBox.square(
      dimension: extent,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: AppBoxDecoration(
          borderRadius: AppRadius.compactCard,
          border: Border.all(
            color: selected ? colors.borderPrimary : colors.borderSoft,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.compactCard,
          child: normalizedImageUrl == null
              ? fallback
              : Image.network(
                  normalizedImageUrl,
                  key: imageKey,
                  fit: BoxFit.cover,
                  cacheWidth: pixelExtent,
                  cacheHeight: pixelExtent,
                  filterQuality: FilterQuality.medium,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return child;
                        }
                        return fallback;
                      },
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _SavedCoverFallback extends StatelessWidget {
  const _SavedCoverFallback({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: selected ? colors.primarySoft : colors.primaryContainer,
        borderRadius: AppRadius.compactCard,
        border: Border.all(color: colors.primary),
      ),
      child: Icon(
        icon,
        color: selected ? colors.onPrimary : colors.primary,
        size: AppSizes.iconLg,
      ),
    );
  }
}

String? _normalizedHttpUrl(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
    return null;
  }
  return normalized;
}
