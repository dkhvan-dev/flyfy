import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final okLabel = MaterialLocalizations.of(context).okButtonLabel;
  final colors = AppDesignSystem.colorsFor(context);

  return showAppModalDialog<void>(
    context: context,
    barrierLabel: 'error-dialog',
    barrierColor: colors.scrim.withValues(alpha: 0.72),
    pageBuilder: (dialogContext, _, _) {
      final dialogColors = AppDesignSystem.colorsFor(dialogContext);
      final dialog = Center(
        child: Padding(
          padding: const AppEdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AppModalDialogCard(
              icon: DecoratedBox(
                decoration: AppBoxDecoration(
                  color: dialogColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: dialogColors.borderPrimary),
                ),
                child: SizedBox.square(
                  dimension: AppSizes.minTapTarget,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: dialogColors.primary,
                    size: AppSizes.iconMd,
                  ),
                ),
              ),
              title: Text(title),
              content: Text(message),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: AppButtonStyles.primary(dialogColors),
                  child: Text(okLabel),
                ),
              ],
            ),
          ),
        ),
      );

      return SafeArea(child: dialog);
    },
  );
}
