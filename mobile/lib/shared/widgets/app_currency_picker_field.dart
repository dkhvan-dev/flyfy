import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

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
      requestFocus: true,
      builder: (context) => _AppCurrencyPickerSheet(
        selectedCode: normalizeAppCurrencyCodeOrDefault(selectedCode),
      ),
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

class _AppCurrencyPickerSheet extends StatefulWidget {
  const _AppCurrencyPickerSheet({required this.selectedCode});

  final String selectedCode;

  @override
  State<_AppCurrencyPickerSheet> createState() =>
      _AppCurrencyPickerSheetState();
}

class _AppCurrencyPickerSheetState extends State<_AppCurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppCurrencyOption> _visibleOptions(AppLocalizations l10n) {
    final query = _normalizeCurrencyPickerQuery(_searchController.text);
    if (query.isEmpty) return appCurrencyOptions;

    return appCurrencyOptions
        .where((option) {
          final label = option.label(l10n);
          final searchable = _normalizeCurrencyPickerQuery(
            '${option.code} ${option.symbol} $label',
          );
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final visibleOptions = _visibleOptions(l10n);

    return AppModalSheetFrame(
      useSafeArea: false,
      onTapOutside: () => Navigator.of(context).maybePop(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          child: SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                var maxHeight = _currencyPickerMaxHeightAboveKeyboard(context);
                if (constraints.maxHeight.isFinite) {
                  maxHeight = maxHeight
                      .clamp(0.0, constraints.maxHeight)
                      .toDouble();
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: DecoratedBox(
                    decoration: AppBoxDecoration(
                      color: colors.surface,
                      borderRadius: AppRadius.sheetTop,
                      border: Border.all(color: colors.borderSoft),
                    ),
                    child: Padding(
                      padding: const AppEdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 5,
                            decoration: AppBoxDecoration(
                              color: colors.borderSoft,
                              borderRadius: AppBorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            onChanged: (_) => setState(() {}),
                            style: AppTextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: AppInputDecoration(
                              hintText: l10n.profileCurrencySearchHint,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: colors.textMuted,
                              ),
                              hintStyle: AppTextStyle(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: colors.surfaceRaised,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppBorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: colors.borderSoft,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppBorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: colors.borderPrimary,
                                  width: 1.3,
                                ),
                              ),
                              contentPadding: const AppEdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: visibleOptions.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const AppEdgeInsets.symmetric(
                                        vertical: 28,
                                      ),
                                      child: Text(
                                        l10n.profileCurrencyNoResults,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: visibleOptions.length,
                                    separatorBuilder: (_, _) => Divider(
                                      height: 1,
                                      color: colors.borderSoft,
                                    ),
                                    itemBuilder: (context, index) {
                                      final option = visibleOptions[index];
                                      final isSelected =
                                          option.code == widget.selectedCode;
                                      return ListTile(
                                        onTap: () => Navigator.of(
                                          context,
                                        ).pop(option.code),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              AppBorderRadius.circular(16),
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: isSelected
                                              ? colors.primary
                                              : colors.surfaceHigh,
                                          foregroundColor: colors.textPrimary,
                                          child: Text(option.symbol),
                                        ),
                                        title: Text(
                                          option.label(l10n),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? Icon(
                                                Icons.check_circle_rounded,
                                                color: colors.primary,
                                              )
                                            : Text(
                                                option.code,
                                                style: AppTextStyle(
                                                  color: colors.textMuted,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

double _currencyPickerMaxHeightAboveKeyboard(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final keyboardInset = mediaQuery.viewInsets.bottom;
  final availableHeight =
      mediaQuery.size.height - keyboardInset - mediaQuery.viewPadding.top - 24;
  final preferredHeight = keyboardInset > 0
      ? availableHeight
      : mediaQuery.size.height * 0.72;
  final upperBound = mediaQuery.size.height * 0.86;
  final lowerBound = upperBound < 260 ? upperBound : 260.0;

  return preferredHeight.clamp(lowerBound, upperBound).toDouble();
}

String _normalizeCurrencyPickerQuery(String value) {
  return value.trim().toLowerCase();
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
