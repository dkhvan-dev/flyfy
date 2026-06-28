import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';

Future<void> showAppLanguageSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final localeProvider = context.read<LocaleProvider>();
  final currentCode = localeProvider.locale.languageCode;
  final selectedCode = await showModalBottomSheet<String>(
    context: context,
    isDismissible: true,
    backgroundColor: AppPalette.transparent,
    barrierColor: AppPalette.black.withValues(alpha: 0.58),
    isScrollControlled: true,
    builder: (sheetContext) {
      final mediaQuery = MediaQuery.of(sheetContext);
      final screenSize = mediaQuery.size;
      final screenWidth = screenSize.width;
      final screenHeight = screenSize.height;
      final textScale = MediaQuery.textScalerOf(
        sheetContext,
      ).scale(1).clamp(1.0, 1.4);
      final isCompact = screenWidth < 375;
      final isShortLayout = screenHeight < 700 || textScale > 1.2;
      final bottomInset = mediaQuery.viewInsets.bottom;
      final maxSheetHeight = (screenHeight - mediaQuery.viewPadding.top - 12)
          .clamp(320.0, screenHeight)
          .toDouble();
      final horizontalPadding = isCompact ? 22.0 : 26.0;
      final sheetRadius = isCompact ? 30.0 : 34.0;
      final visualScale = isShortLayout ? 0.82 : 1.0;
      final iconWrapSize = (isCompact ? 124.0 : 140.0) * visualScale;
      final glowSize = iconWrapSize + (isCompact ? 20.0 : 22.0);
      final iconSize = (isCompact ? 50.0 : 58.0) * visualScale;
      final topPadding = isShortLayout ? 20.0 : (isCompact ? 24.0 : 28.0);
      final bottomPadding = isShortLayout ? 20.0 : (isCompact ? 24.0 : 30.0);
      final handleToIconGap = isShortLayout ? 20.0 : (isCompact ? 26.0 : 34.0);
      final iconToTitleGap = isShortLayout ? 18.0 : (isCompact ? 22.0 : 26.0);
      final titleToOptionsGap = isShortLayout
          ? 22.0
          : (isCompact ? 28.0 : 34.0);
      final optionGap = isShortLayout ? 12.0 : (isCompact ? 14.0 : 16.0);

      return SafeArea(
        top: false,
        child: Padding(
          padding: AppEdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: ClipRRect(
              borderRadius: AppBorderRadius.vertical(
                top: AppRadiusValue.circular(sheetRadius),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: AppBoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppPalette.warmInk70, AppPalette.warmInk25],
                    ),
                    borderRadius: AppBorderRadius.vertical(
                      top: AppRadiusValue.circular(sheetRadius),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppPalette.white.withValues(alpha: 0.08),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.black.withValues(alpha: 0.24),
                        blurRadius: 40,
                        offset: const Offset(0, -12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: AppBoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppPalette.white.withValues(alpha: 0.02),
                                  AppPalette.transparent,
                                ],
                                stops: const [0, 0.16],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -24,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 110,
                            decoration: AppBoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, 0.7),
                                radius: 0.95,
                                colors: [
                                  AppPalette.primary.withValues(alpha: 0.08),
                                  AppPalette.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Padding(
                          padding: AppEdgeInsets.fromLTRB(
                            horizontalPadding,
                            topPadding,
                            horizontalPadding,
                            bottomPadding,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 76,
                                  height: 7,
                                  decoration: AppBoxDecoration(
                                    color: AppPalette.primary.withValues(
                                      alpha: 0.45,
                                    ),
                                    borderRadius: AppBorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppPalette.primary.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: handleToIconGap),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: glowSize,
                                    height: glowSize,
                                    decoration: AppBoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppPalette.primary.withValues(
                                            alpha: 0.26,
                                          ),
                                          AppPalette.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          AppPalette.primary.withValues(
                                            alpha: 0.04,
                                          ),
                                          AppPalette.transparent,
                                        ],
                                        stops: const [0, 0.3, 0.52, 0.78],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: iconWrapSize,
                                    height: iconWrapSize,
                                    decoration: AppBoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(0, -0.25),
                                        colors: [
                                          AppPalette.primary.withValues(
                                            alpha: 0.05,
                                          ),
                                          AppPalette.primary.withValues(
                                            alpha: 0.01,
                                          ),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: AppPalette.primary.withValues(
                                          alpha: 0.36,
                                        ),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppPalette.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 28,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.language_rounded,
                                      size: iconSize,
                                      color: AppPalette.primary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: iconToTitleGap),
                              Text(
                                l10n.appLanguageTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyle(
                                  color: AppPalette.textPrimary,
                                  fontSize: isCompact ? 16 : 18,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              SizedBox(height: titleToOptionsGap),
                              for (final option in _languageOptions) ...[
                                _LanguageOptionTile(
                                  label: option.label,
                                  code: option.code.toUpperCase(),
                                  isSelected: currentCode == option.code,
                                  onTap: () => Navigator.of(
                                    sheetContext,
                                  ).pop(option.code),
                                ),
                                if (option != _languageOptions.last)
                                  SizedBox(height: optionGap),
                              ],
                            ],
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
      );
    },
  );

  if (selectedCode == null || !context.mounted) return;
  await localeProvider.setLocale(selectedCode);
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 375;
    return Semantics(
      button: true,
      enabled: true,
      selected: isSelected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: AppPalette.transparent,
          child: InkWell(
            borderRadius: AppBorderRadius.circular(isCompact ? 20 : 24),
            onTap: onTap,
            child: Ink(
              padding: AppEdgeInsets.symmetric(
                horizontal: isCompact ? 18 : 20,
                vertical: isCompact ? 15 : 18,
              ),
              decoration: AppBoxDecoration(
                color: isSelected
                    ? AppPalette.primary.withValues(alpha: 0.17)
                    : AppPalette.white.withValues(alpha: 0.035),
                borderRadius: AppBorderRadius.circular(isCompact ? 20 : 24),
                border: Border.all(
                  color: isSelected
                      ? AppPalette.primary
                      : AppPalette.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: isCompact ? 42 : 46,
                    height: isCompact ? 42 : 46,
                    alignment: Alignment.center,
                    decoration: AppBoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppPalette.primary.withValues(alpha: 0.22)
                          : AppPalette.white.withValues(alpha: 0.06),
                    ),
                    child: Text(
                      code,
                      style: AppTextStyle(
                        color: AppPalette.primary,
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 14 : 16),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: isCompact ? 15 : 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 10 : 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('selected'),
                            color: AppPalette.primary,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            key: const ValueKey('idle'),
                            color: AppPalette.white.withValues(alpha: 0.18),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}

const List<_LanguageOption> _languageOptions = [
  _LanguageOption(code: 'ru', label: 'Русский'),
  _LanguageOption(code: 'en', label: 'English'),
  _LanguageOption(code: 'kk', label: 'Қазақша'),
];
