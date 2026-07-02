import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../service_catalog.dart';

class ServiceGridStyle {
  const ServiceGridStyle({
    required this.availableBackgroundColor,
    required this.availableForegroundColor,
    required this.availableTextColor,
    required this.availableBorderColor,
    required this.unavailableBackgroundColor,
    required this.unavailableForegroundColor,
    required this.unavailableTextColor,
    required this.unavailableBorderColor,
    required this.splashColor,
    required this.highlightColor,
  });

  final Color availableBackgroundColor;
  final Color availableForegroundColor;
  final Color availableTextColor;
  final Color availableBorderColor;
  final Color unavailableBackgroundColor;
  final Color unavailableForegroundColor;
  final Color unavailableTextColor;
  final Color unavailableBorderColor;
  final Color splashColor;
  final Color highlightColor;

  static const _v2Dark = ServiceGridStyle(
    availableBackgroundColor: AppPalette.surfaceRaised,
    availableForegroundColor: AppPalette.primary,
    availableTextColor: AppPalette.textPrimary,
    availableBorderColor: AppPalette.borderSoft,
    unavailableBackgroundColor: AppPalette.surface,
    unavailableForegroundColor: AppPalette.textDisabled,
    unavailableTextColor: AppPalette.textMuted,
    unavailableBorderColor: AppPalette.border,
    splashColor: AppPalette.borderPrimary,
    highlightColor: AppPalette.transparent,
  );

  static ServiceGridStyle v2(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return ServiceGridStyle(
      availableBackgroundColor: colors.surfaceRaised,
      availableForegroundColor: colors.primary,
      availableTextColor: colors.textPrimary,
      availableBorderColor: colors.border,
      unavailableBackgroundColor: colors.surface,
      unavailableForegroundColor: colors.textDisabled,
      unavailableTextColor: colors.textMuted,
      unavailableBorderColor: colors.border,
      splashColor: colors.borderPrimary,
      highlightColor: colors.transparent,
    );
  }

  static ServiceGridStyle v2Dark() => _v2Dark;
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.services,
    required this.onServiceTap,
    this.style,
  });

  final List<TravelServiceEntry> services;
  final ValueChanged<TravelServiceEntry> onServiceTap;
  final ServiceGridStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? ServiceGridStyle.v2(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) return const SizedBox.shrink();

        final isCompact = width < 375;
        final horizontalGap = isCompact ? 12.0 : 24.0;
        final verticalGap = isCompact ? 18.0 : 26.0;
        var columnCount = width >= 600 ? 4 : 3;
        while (columnCount > 1 &&
            width - horizontalGap * (columnCount - 1) <= 0) {
          columnCount -= 1;
        }
        final tileWidth =
            (width - horizontalGap * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: horizontalGap,
          runSpacing: verticalGap,
          children: [
            for (final service in services)
              SizedBox(
                width: tileWidth,
                child: _ServiceTile(
                  service: service,
                  isCompact: isCompact,
                  style: resolvedStyle,
                  onServiceTap: onServiceTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.isCompact,
    required this.style,
    required this.onServiceTap,
  });

  final TravelServiceEntry service;
  final bool isCompact;
  final ServiceGridStyle style;
  final ValueChanged<TravelServiceEntry> onServiceTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = service.isAvailable && service.route.trim().isNotEmpty;
    final foregroundColor = isEnabled
        ? style.availableForegroundColor
        : style.unavailableForegroundColor;
    final textColor = isEnabled
        ? style.availableTextColor
        : style.unavailableTextColor;
    final backgroundColor = isEnabled
        ? style.availableBackgroundColor
        : style.unavailableBackgroundColor;
    final borderColor = isEnabled
        ? style.availableBorderColor
        : style.unavailableBorderColor;
    final iconSize = isCompact ? 26.0 : 31.0;
    final iconLabelGap = isCompact ? 7.0 : 9.0;
    final verticalPadding = isCompact ? 10.0 : 12.0;
    final labelFontSize = isCompact ? 11.0 : 12.0;
    final minTileHeight = iconSize + iconLabelGap + 28 + verticalPadding * 2;

    return Semantics(
      container: true,
      button: true,
      enabled: isEnabled,
      label: service.title,
      onTap: isEnabled ? () => onServiceTap(service) : null,
      child: ExcludeSemantics(
        child: Material(
          color: style.highlightColor,
          child: InkWell(
            onTap: isEnabled ? () => onServiceTap(service) : null,
            borderRadius: AppBorderRadius.circular(16),
            splashColor: isEnabled ? style.splashColor : style.highlightColor,
            highlightColor: style.highlightColor,
            child: Ink(
              decoration: AppBoxDecoration(
                color: backgroundColor,
                borderRadius: AppBorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minTileHeight),
                child: Padding(
                  padding: AppEdgeInsets.symmetric(
                    horizontal: isCompact ? 6 : 8,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        service.icon,
                        color: foregroundColor,
                        size: iconSize,
                      ),
                      SizedBox(height: iconLabelGap),
                      Text(
                        service.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyle(
                          color: textColor,
                          fontSize: labelFontSize,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
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
  }
}
