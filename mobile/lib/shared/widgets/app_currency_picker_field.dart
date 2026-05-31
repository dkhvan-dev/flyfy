import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../formatters/app_money_formatter.dart';

class AppCurrencyPickerField extends StatelessWidget {
  const AppCurrencyPickerField({
    super.key,
    required this.label,
    required this.selectedCode,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.surfaceColor = const Color(0xFF2D2115),
  });

  final String label;
  final String selectedCode;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;
  final Color surfaceColor;

  AppCurrencyOption get _selectedOption {
    final normalized = normalizeAppCurrencyCodeOrDefault(selectedCode);
    return appCurrencyOptions.firstWhere(
      (option) => option.code == normalized,
      orElse: () => AppCurrencyOption(code: normalized),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final selected = normalizeAppCurrencyCodeOrDefault(selectedCode);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2115),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: appCurrencyOptions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.accent.withValues(alpha: 0.10),
                ),
                itemBuilder: (context, index) {
                  final option = appCurrencyOptions[index];
                  final isSelected = option.code == selected;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(option.code),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppColors.accent
                          : const Color(0xFF3A2A1D),
                      foregroundColor: Colors.white,
                      child: Text(option.symbol),
                    ),
                    title: Text(
                      option.label(l10n),
                      style: const TextStyle(
                        color: Color(0xFFFFF8F0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                          )
                        : Text(
                            option.code,
                            style: const TextStyle(
                              color: Color(0xFFA99683),
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
    final selectedOption = _selectedOption;
    final borderColor = errorText == null
        ? AppColors.accent.withValues(alpha: 0.10)
        : const Color(0xFFFFB199);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF3E8DC),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Text(
                    selectedOption.symbol,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.65),
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
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFFFFF8F0)
                            : const Color(0xFFFFF8F0).withValues(alpha: 0.65),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled
                        ? const Color(0xFFA99683)
                        : const Color(0xFFA99683).withValues(alpha: 0.55),
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
            style: const TextStyle(
              color: Color(0xFFFFB199),
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
