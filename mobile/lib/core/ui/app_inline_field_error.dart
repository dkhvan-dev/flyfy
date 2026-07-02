import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class AppInlineFieldError extends StatelessWidget {
  const AppInlineFieldError({
    super.key,
    required this.message,
    this.padding = const AppEdgeInsets.only(top: 8),
  });

  final String message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.danger, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: colors.danger,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
