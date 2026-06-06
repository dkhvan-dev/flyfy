import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../service_catalog.dart';

const _availableBackgroundColor = Color(0xFF43280D);
const _availableTextColor = Color(0xFFF2E5D7);
const _unavailableBackgroundColor = Color(0xFF2F2B27);
const _unavailableForegroundColor = Color(0xFF9B8976);
const _unavailableTextColor = Color(0xFFB5A694);
const _unavailableBorderColor = Color(0xFF5C5147);

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
        ? AppColors.accent
        : _unavailableForegroundColor;
    final textColor = isEnabled ? _availableTextColor : _unavailableTextColor;
    final backgroundColor = isEnabled
        ? _availableBackgroundColor
        : _unavailableBackgroundColor;
    final borderColor = isEnabled
        ? Colors.transparent
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
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? () => onServiceTap(service) : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: isEnabled
                ? AppColors.accent.withValues(alpha: 0.10)
                : Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minTileHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
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
                        style: TextStyle(
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
