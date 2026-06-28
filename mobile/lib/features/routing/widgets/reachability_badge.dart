import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class ReachabilityBadge extends StatelessWidget {
  const ReachabilityBadge({super.key, required this.isReachable, this.label});

  final bool isReachable;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isReachable
        ? AppPalette.greenSurfaceHigh09
        : theme.colorScheme.errorContainer;
    final foreground = isReachable
        ? AppPalette.white
        : theme.colorScheme.onErrorContainer;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: background.withValues(alpha: 0.88),
        borderRadius: AppBorderRadius.circular(8),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label ?? (isReachable ? 'Reachable' : 'Unavailable'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
