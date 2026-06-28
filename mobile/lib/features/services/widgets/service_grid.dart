import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../service_catalog.dart';

const _availableBackgroundColor = AppPalette.warmSurface74;
const _availableTextColor = AppPalette.orangeLight33;
const _unavailableBackgroundColor = AppPalette.warmSurface38;
const _unavailableForegroundColor = AppPalette.warmMuted15;
const _unavailableTextColor = AppPalette.orangeSoft07;
const _unavailableBorderColor = AppPalette.warmSurfaceHigh10;

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.services,
    required this.onServiceTap,
  });

  final List<TravelServiceEntry> services;
  final ValueChanged<TravelServiceEntry> onServiceTap;

  @override
  Widget build(BuildContext context) {
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
    required this.onServiceTap,
  });

  final TravelServiceEntry service;
  final bool isCompact;
  final ValueChanged<TravelServiceEntry> onServiceTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = service.isAvailable && service.route.trim().isNotEmpty;
    final foregroundColor = isEnabled
        ? AppPalette.primary
        : _unavailableForegroundColor;
    final textColor = isEnabled ? _availableTextColor : _unavailableTextColor;
    final backgroundColor = isEnabled
        ? _availableBackgroundColor
        : _unavailableBackgroundColor;
    final borderColor = isEnabled
        ? AppPalette.transparent
        : _unavailableBorderColor;
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
          color: AppPalette.transparent,
          child: InkWell(
            onTap: isEnabled ? () => onServiceTap(service) : null,
            borderRadius: AppBorderRadius.circular(16),
            splashColor: isEnabled
                ? AppPalette.primary.withValues(alpha: 0.10)
                : AppPalette.transparent,
            highlightColor: AppPalette.transparent,
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
