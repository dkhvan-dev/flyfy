import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class ReachabilityBadge extends StatelessWidget {
  const ReachabilityBadge({super.key, required this.isReachable, this.label});

  final bool isReachable;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final accent = isReachable ? colors.success : colors.danger;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label ?? (isReachable ? 'Reachable' : 'Unavailable'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
