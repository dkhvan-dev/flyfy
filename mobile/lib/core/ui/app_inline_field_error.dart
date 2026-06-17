import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppInlineFieldError extends StatelessWidget {
  const AppInlineFieldError({
    super.key,
    required this.message,
    this.padding = const EdgeInsets.only(top: 8),
  });

  final String message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.destructive,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.destructive,
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
