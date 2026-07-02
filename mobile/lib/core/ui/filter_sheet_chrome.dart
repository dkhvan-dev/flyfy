import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class AppFilterSheetHeader extends StatelessWidget {
  const AppFilterSheetHeader({
    super.key,
    required this.title,
    required this.clearLabel,
    required this.onClear,
    this.height,
    this.horizontalPadding,
    this.titleFontSize,
    this.clearFontSize,
  });

  final String title;
  final String clearLabel;
  final VoidCallback onClear;
  final double? height;
  final double? horizontalPadding;
  final double? titleFontSize;
  final double? clearFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final effectiveHeight = height ?? 46;
    final effectiveHorizontalPadding = horizontalPadding ?? 18;
    final effectiveTitleSize = titleFontSize ?? 16;
    final effectiveClearSize = clearFontSize ?? 12;
    final reservedActionWidth = textScaler.scale(86);

    return Container(
      height: effectiveHeight,
      padding: AppEdgeInsets.symmetric(horizontal: effectiveHorizontalPadding),
      decoration: AppBoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSoft)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: AppEdgeInsets.symmetric(horizontal: reservedActionWidth),
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: effectiveTitleSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: AppEdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                clearLabel.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  fontSize: effectiveClearSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppFilterApplyButton extends StatelessWidget {
  const AppFilterApplyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.minHeight = 52,
    this.fontSize,
    this.borderRadius,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double minHeight;
  final double? fontSize;
  final double? borderRadius;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final effectiveFontSize = fontSize ?? 17;
    final effectiveIconSize = (effectiveFontSize + 1).clamp(16, 20).toDouble();

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.72),
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textPrimary.withValues(alpha: 0.82),
          minimumSize: Size(0, minHeight),
          padding: const AppEdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.circular(borderRadius ?? 999),
          ),
          textStyle: AppTextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: effectiveIconSize,
                height: effectiveIconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: effectiveIconSize),
                  ],
                ],
              ),
      ),
    );
  }
}
