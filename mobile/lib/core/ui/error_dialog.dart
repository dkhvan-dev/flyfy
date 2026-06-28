import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final okLabel = MaterialLocalizations.of(context).okButtonLabel;

  return showAppModalDialog<void>(
    context: context,
    title: title,
    subtitle: message,
    icon: Icons.warning_amber_rounded,
    barrierDismissible: true,
    barrierLabel: 'error-dialog',
    barrierColor: AppPalette.black.withValues(alpha: 0.72),
    actions: [
      AppModalAction<void>(
        label: okLabel,
        variant: AppModalActionVariant.primary,
      ),
    ],
  );
}
