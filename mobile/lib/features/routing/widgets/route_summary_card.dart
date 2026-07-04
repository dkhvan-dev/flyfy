import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../models/routing_models.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({super.key, required this.route});

  final RouteResponseVm route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final duration = _formatDuration(route.durationSeconds, l10n);
    final distance = _formatDistance(route.distanceMeters, l10n);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceRaised, colors.secondaryContainer],
        ),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: colors.borderSecondary),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: AppBoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: AppBorderRadius.circular(8),
                    border: Border.all(color: colors.borderSecondary),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: colors.secondary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.routeSummaryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _profileLabel(route.profile, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackMetrics = constraints.maxWidth < 320;
                final metrics = [
                  _RouteMetric(
                    icon: Icons.schedule_rounded,
                    label: l10n.routeSummaryDuration,
                    value: duration,
                  ),
                  _RouteMetric(
                    icon: Icons.straighten_rounded,
                    label: l10n.routeSummaryDistance,
                    value: distance,
                  ),
                ];

                if (stackMetrics) {
                  return Column(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _RouteMetricTile(metric: metrics[i]),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _RouteMetricTile(metric: metrics[i])),
                    ],
                  ],
                );
              },
            ),
            if (route.warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                route.warnings.first.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _profileLabel(RouteProfile profile, AppLocalizations l10n) {
    return switch (profile) {
      RouteProfile.touristWalk => l10n.routeProfileTouristWalk,
      RouteProfile.fastWalk => l10n.routeProfileFastWalk,
      RouteProfile.bikeCity => l10n.routeProfileBikeCity,
      RouteProfile.carStandard => l10n.routeProfileCarStandard,
      RouteProfile.guideRoute => l10n.routeProfileGuideRoute,
      RouteProfile.dayPlan => l10n.routeProfileDayPlan,
      RouteProfile.transit => l10n.routeProfileTransit,
    };
  }

  String _formatDuration(int seconds, AppLocalizations l10n) {
    final minutes = (seconds / 60).round().clamp(1, 1440);
    return l10n.routeDurationMinutesShort(minutes);
  }

  String _formatDistance(double meters, AppLocalizations l10n) {
    if (meters <= 0) {
      return l10n.mapDistancePending;
    }
    if (meters >= 1000) {
      final kilometers = meters / 1000;
      return l10n.routeDistanceKilometersShort(
        kilometers.toStringAsFixed(kilometers >= 10 ? 0 : 1),
      );
    }
    return l10n.routeDistanceMetersShort(meters.round());
  }
}

class _RouteMetric {
  const _RouteMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _RouteMetricTile extends StatelessWidget {
  const _RouteMetricTile({required this.metric});

  final _RouteMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(metric.icon, color: colors.secondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
