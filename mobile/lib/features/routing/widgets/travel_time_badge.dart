import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class TravelTimeBadge extends StatelessWidget {
  const TravelTimeBadge({
    super.key,
    required this.durationSeconds,
    this.distanceMeters,
  });

  final int durationSeconds;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _label(l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n) {
    final minutes = (durationSeconds / 60).round().clamp(1, 1440);
    final distance = distanceMeters;
    if (distance == null || distance <= 0) {
      return l10n.routeDurationMinutesShort(minutes);
    }
    final km = distance / 1000;
    final distanceLabel = l10n.routeDistanceKilometersShort(
      km.toStringAsFixed(km >= 10 ? 0 : 1),
    );
    return l10n.routeTravelTimeDistanceShort(
      l10n.routeDurationMinutesShort(minutes),
      distanceLabel,
    );
  }
}
