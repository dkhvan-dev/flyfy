import 'package:flutter/material.dart';

class ReachabilityBadge extends StatelessWidget {
  const ReachabilityBadge({super.key, required this.isReachable, this.label});

  final bool isReachable;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isReachable
        ? const Color(0xFF1B5E20)
        : theme.colorScheme.errorContainer;
    final foreground = isReachable
        ? Colors.white
        : theme.colorScheme.onErrorContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
