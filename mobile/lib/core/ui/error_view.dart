import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../l10n/generated/app_localizations.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return Center(
      child: Padding(
        padding: const AppEdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 72, color: colors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyle(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: AppButtonStyles.primary(colors),
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
