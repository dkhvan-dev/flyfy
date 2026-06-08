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

class AppFilterPaletteDialog extends StatelessWidget {
  const AppFilterPaletteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
    this.icon = Icons.tune_rounded,
  });

  final String title;
  final String message;
  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isCompact = screenWidth < 375;
    final maxDialogHeight =
        (screenHeight - mediaQuery.viewPadding.vertical - 48)
            .clamp(300.0, screenHeight)
            .toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 386, maxHeight: maxDialogHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF21170D),
              border: Border.all(color: const Color(0x293A270F)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 22 : 26,
                  isCompact ? 22 : 26,
                  isCompact ? 22 : 26,
                  isCompact ? 20 : 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isCompact ? 54 : 58,
                      height: isCompact ? 54 : 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2C2118),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.accent,
                        size: isCompact ? 25 : 27,
                      ),
                    ),
                    SizedBox(height: isCompact ? 18 : 20),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFFFF7EC),
                        fontSize: isCompact ? 21 : 23,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: TextStyle(
                        color: const Color(0xFFE0D4C6).withValues(alpha: 0.88),
                        fontSize: isCompact ? 14 : 15,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: isCompact ? 22 : 26),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useStackedActions =
                            constraints.maxWidth < 318 || textScale > 1.25;
                        final actionWidth = useStackedActions
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            SizedBox(
                              width: actionWidth,
                              child: _AppFilterPaletteDialogActionButton(
                                label: secondaryLabel,
                                onTap: onSecondary,
                                isPrimary: false,
                              ),
                            ),
                            SizedBox(
                              width: actionWidth,
                              child: _AppFilterPaletteDialogActionButton(
                                label: primaryLabel,
                                onTap: onPrimary,
                                isPrimary: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppFilterPaletteDialogActionButton extends StatelessWidget {
  const _AppFilterPaletteDialogActionButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isPrimary
        ? AppColors.textPrimary
        : const Color(0xFFD8C7B7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Ink(
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.accent : const Color(0xFF2C2118),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPrimary ? AppColors.accent : const Color(0xFF3B260D),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
