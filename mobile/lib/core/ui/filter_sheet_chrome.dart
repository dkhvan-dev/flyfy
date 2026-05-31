import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppDismissibleModalSheet extends StatelessWidget {
  const AppDismissibleModalSheet({
    super.key,
    required this.child,
    this.alignment = Alignment.bottomCenter,
    this.useSafeArea = true,
    this.safeAreaTop = false,
    this.safeAreaBottom = false,
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final bool useSafeArea;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        Align(alignment: alignment, child: child),
      ],
    );

    if (!useSafeArea) return content;

    return SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: content);
  }
}

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
    final textScaler = MediaQuery.textScalerOf(context);
    final effectiveHeight = height ?? 46;
    final effectiveHorizontalPadding = horizontalPadding ?? 18;
    final effectiveTitleSize = titleFontSize ?? 16;
    final effectiveClearSize = clearFontSize ?? 12;
    final reservedActionWidth = textScaler.scale(86);

    return Container(
      height: effectiveHeight,
      padding: EdgeInsets.symmetric(horizontal: effectiveHorizontalPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF3B260D))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: reservedActionWidth),
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
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
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                clearLabel.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
    final effectiveFontSize = fontSize ?? 17;
    final effectiveIconSize = (effectiveFontSize + 1).clamp(16, 20).toDouble();

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.72),
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textPrimary.withValues(
            alpha: 0.82,
          ),
          minimumSize: Size(0, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 999),
          ),
          textStyle: TextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: effectiveIconSize,
                height: effectiveIconSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
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
