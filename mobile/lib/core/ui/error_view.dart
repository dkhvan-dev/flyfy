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

    return Center(
      child: Padding(
        padding: const AppEdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 72,
              color: AppPalette.materialDangerAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const AppTextStyle(color: AppPalette.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.primary,
                foregroundColor: AppPalette.white,
              ),
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
