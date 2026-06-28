import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'error-dialog',
    barrierColor: AppPalette.black.withValues(alpha: 0.72),
    pageBuilder: (context, _, _) {
      final okLabel = MaterialLocalizations.of(context).okButtonLabel;

      return SafeArea(
        child: Center(
          child: Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: AppPalette.warmSurface18,
                borderRadius: AppBorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: AppBoxDecoration(
                    borderRadius: AppBorderRadius.circular(28),
                    border: Border.all(color: AppPalette.outlineOverlayLight),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.primary.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const AppEdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: AppBoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.primary.withValues(alpha: 0.14),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppPalette.primary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const AppTextStyle(
                            color: AppPalette.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const AppTextStyle(
                            color: AppPalette.textCoolSecondary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.primary,
                              foregroundColor: AppPalette.textPrimary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppBorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              okLabel,
                              style: const AppTextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
