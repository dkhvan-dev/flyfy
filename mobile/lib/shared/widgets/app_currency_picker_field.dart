import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../l10n/generated/app_localizations.dart';
import '../formatters/app_money_formatter.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

class AppCurrencyPickerField extends StatelessWidget {
  const AppCurrencyPickerField({
    super.key,
    required this.label,
    required this.selectedCode,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.surfaceColor,
  });

  final String label;
  final String selectedCode;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;
  final Color? surfaceColor;

  AppCurrencyOption get _selectedOption {
    final normalized = normalizeAppCurrencyCodeOrDefault(selectedCode);
    return appCurrencyOptions.firstWhere(
      (option) => option.code == normalized,
      orElse: () => AppCurrencyOption(code: normalized),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final colors = AppDesignSystem.colorsFor(context);

    final result = await showAppModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: colors.transparent,
      builder: (context) {
        final sheetColors = AppDesignSystem.colorsFor(context);
        final l10n = AppLocalizations.of(context)!;
        final selected = normalizeAppCurrencyCodeOrDefault(selectedCode);
        return SafeArea(
          child: Padding(
            padding: const AppEdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: AppBoxDecoration(
                color: sheetColors.surface,
                borderRadius: AppBorderRadius.circular(28),
                border: Border.all(color: sheetColors.borderSoft),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const AppEdgeInsets.all(12),
                itemCount: appCurrencyOptions.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: sheetColors.borderSoft),
                itemBuilder: (context, index) {
                  final option = appCurrencyOptions[index];
                  final isSelected = option.code == selected;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(option.code),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? sheetColors.primary
                          : sheetColors.surfaceHigh,
                      foregroundColor: sheetColors.textPrimary,
                      child: Text(option.symbol),
                    ),
                    title: Text(
                      option.label(l10n),
                      style: AppTextStyle(
                        color: sheetColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: sheetColors.primary,
                          )
                        : Text(
                            option.code,
                            style: AppTextStyle(
                              color: sheetColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (result != null && result != normalizeAppCurrencyCode(selectedCode)) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final selectedOption = _selectedOption;
    final borderColor = errorText == null
        ? colors.borderPrimary
        : colors.danger;
    final effectiveSurfaceColor = surfaceColor ?? colors.surfaceRaised;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: effectiveSurfaceColor,
          borderRadius: AppBorderRadius.circular(24),
          child: InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: AppBorderRadius.circular(24),
            child: Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const AppEdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: AppBoxDecoration(
                borderRadius: AppBorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Text(
                    selectedOption.symbol,
                    style: AppTextStyle(
                      color: enabled
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0.65),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      selectedOption.label(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: enabled
                            ? colors.textPrimary
                            : colors.textPrimary.withValues(alpha: 0.65),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled
                        ? colors.textMuted
                        : colors.textMuted.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: AppTextStyle(
              color: colors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class AppCurrencyOption {
  const AppCurrencyOption({required this.code});

  final String code;

  String get symbol => appCurrencySymbol(code);

  String label(AppLocalizations l10n) {
    return switch (code) {
      'KZT' => l10n.createCurrencyKzt,
      'USD' => l10n.createCurrencyUsd,
      'EUR' => l10n.createCurrencyEur,
      'RUB' => l10n.createCurrencyRub,
      'GBP' => l10n.createCurrencyGbp,
      _ => code,
    };
  }
}

const appCurrencyOptions = [
  AppCurrencyOption(code: 'KZT'),
  AppCurrencyOption(code: 'USD'),
  AppCurrencyOption(code: 'EUR'),
  AppCurrencyOption(code: 'RUB'),
  AppCurrencyOption(code: 'GBP'),
];
