import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/routing_models.dart';

class RouteModeSelector extends StatelessWidget {
  static const List<RouteProfile> _defaultProfiles = [
    RouteProfile.touristWalk,
    RouteProfile.bikeCity,
    RouteProfile.carStandard,
  ];

  const RouteModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabledProfiles = _defaultProfiles,
  });

  final RouteProfile selected;
  final ValueChanged<RouteProfile> onChanged;
  final List<RouteProfile> enabledProfiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final visibleProfiles = _visibleProfiles;
    if (visibleProfiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedProfile = visibleProfiles.contains(selected)
        ? selected
        : visibleProfiles.first;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.18),
            const Color(0xFF2A1907).withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<RouteProfile>(
            segments: [
              for (final profile in visibleProfiles)
                ButtonSegment<RouteProfile>(
                  value: profile,
                  icon: Icon(_icon(profile), size: 17),
                  label: Text(
                    _shortLabel(profile, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {selectedProfile},
            onSelectionChanged: (value) {
              final next = value.firstOrNull;
              if (next != null && next != selected) {
                onChanged(next);
              }
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(
                theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.textPrimary;
                }
                return const Color(0xFFFFE6B8);
              }),
              iconColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.textPrimary;
                }
                return AppColors.accent;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.accent;
                }
                return Colors.white.withValues(alpha: 0.06);
              }),
              side: WidgetStateProperty.resolveWith((states) {
                final alpha = states.contains(WidgetState.selected)
                    ? 0.76
                    : 0.24;
                return BorderSide(
                  color: AppColors.accent.withValues(alpha: alpha),
                );
              }),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<RouteProfile> get _visibleProfiles {
    return [
      for (final profile in enabledProfiles)
        if (profile != RouteProfile.fastWalk) profile,
    ];
  }

  IconData _icon(RouteProfile profile) {
    return switch (profile) {
      RouteProfile.touristWalk => Icons.directions_walk_rounded,
      RouteProfile.fastWalk => Icons.directions_walk_rounded,
      RouteProfile.bikeCity => Icons.directions_bike_rounded,
      RouteProfile.carStandard => Icons.directions_car_filled_rounded,
      RouteProfile.guideRoute => Icons.route_rounded,
      RouteProfile.dayPlan => Icons.today_rounded,
      RouteProfile.transit => Icons.directions_transit_filled_rounded,
    };
  }

  String _shortLabel(RouteProfile profile, AppLocalizations l10n) {
    return switch (profile) {
      RouteProfile.touristWalk => l10n.routeProfileTouristWalkShort,
      RouteProfile.fastWalk => l10n.routeProfileFastWalkShort,
      RouteProfile.bikeCity => l10n.routeProfileBikeCityShort,
      RouteProfile.carStandard => l10n.routeProfileCarStandardShort,
      RouteProfile.guideRoute => l10n.routeProfileGuideRouteShort,
      RouteProfile.dayPlan => l10n.routeProfileDayPlanShort,
      RouteProfile.transit => l10n.routeProfileTransitShort,
    };
  }
}
