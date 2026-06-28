import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../l10n/generated/app_localizations.dart';

class InflapPaginationBar extends StatelessWidget {
  const InflapPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.padding = AppEdgeInsets.zero,
    this.showLabel = true,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;
  final EdgeInsetsGeometry padding;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final page = currentPage.clamp(1, totalPages).toInt();
    final l10n = AppLocalizations.of(context);
    final previousLabel = l10n?.commonPaginationPrevious ?? 'Previous page';
    final nextLabel = l10n?.commonPaginationNext ?? 'Next page';
    final semanticLabel =
        l10n?.commonPaginationLabel(page, totalPages) ??
        'Page $page of $totalPages';

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final slots = _buildSlots(page, totalPages, width);
          final metrics = _PaginationMetrics.fit(
            availableWidth: width,
            slots: slots,
            currentPage: page,
          );

          return Semantics(
            container: true,
            label: semanticLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: width,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PaginationArrowButton(
                            direction: _PaginationArrowDirection.previous,
                            metrics: metrics,
                            enabled: onPageChanged != null && page > 1,
                            tooltip: previousLabel,
                            onTap: () => onPageChanged?.call(page - 1),
                          ),
                          SizedBox(width: metrics.gap),
                          for (var i = 0; i < slots.length; i++) ...[
                            _PaginationSlotWidget(
                              slot: slots[i],
                              currentPage: page,
                              totalPages: totalPages,
                              metrics: metrics,
                              onPageChanged: onPageChanged,
                            ),
                            if (i != slots.length - 1)
                              SizedBox(width: metrics.gap),
                          ],
                          SizedBox(width: metrics.gap),
                          _PaginationArrowButton(
                            direction: _PaginationArrowDirection.next,
                            metrics: metrics,
                            enabled: onPageChanged != null && page < totalPages,
                            tooltip: nextLabel,
                            onTap: () => onPageChanged?.call(page + 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showLabel) ...[
                  SizedBox(height: metrics.labelGap),
                  _PaginationLabel(
                    currentPage: page,
                    totalPages: totalPages,
                    metrics: metrics,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaginationMetrics {
  const _PaginationMetrics({
    required this.pageSize,
    required this.activeSize,
    required this.activeOuterSize,
    required this.arrowSize,
    required this.dotWidth,
    required this.gap,
    required this.labelGap,
    required this.numberFontSize,
    required this.activeNumberFontSize,
    required this.dotsFontSize,
    required this.arrowIconSize,
    required this.labelFontSize,
  });

  final double pageSize;
  final double activeSize;
  final double activeOuterSize;
  final double arrowSize;
  final double dotWidth;
  final double gap;
  final double labelGap;
  final double numberFontSize;
  final double activeNumberFontSize;
  final double dotsFontSize;
  final double arrowIconSize;
  final double labelFontSize;

  factory _PaginationMetrics.fit({
    required double availableWidth,
    required List<_PaginationSlot> slots,
    required int currentPage,
  }) {
    final width = availableWidth.isFinite && availableWidth > 0
        ? availableWidth
        : 1.0;

    const pageWeight = 1.0;
    const activeOuterWeight = 1.34;
    const arrowWeight = 1.04;
    const dotWeight = 0.48;
    const gapWeight = 0.14;

    final slotWeight = slots.fold<double>(0, (sum, slot) {
      if (slot.isDots) {
        return sum + dotWeight;
      }

      return sum + (slot.page == currentPage ? activeOuterWeight : pageWeight);
    });
    final totalGapWeight = (slots.length + 1) * gapWeight;
    final totalWeight = slotWeight + arrowWeight * 2 + totalGapWeight;
    final maxUnit = (width * 0.092).clamp(28.0, 38.0).toDouble();
    final unit = math.min(width / totalWeight, maxUnit);
    final activeOuterSize = unit * activeOuterWeight;
    final activeSize = activeOuterSize * 0.78;

    return _PaginationMetrics(
      pageSize: unit * pageWeight,
      activeSize: activeSize,
      activeOuterSize: activeOuterSize,
      arrowSize: unit * arrowWeight,
      dotWidth: unit * dotWeight,
      gap: unit * gapWeight,
      labelGap: unit * 0.26,
      numberFontSize: unit * 0.46,
      activeNumberFontSize: activeSize * 0.46,
      dotsFontSize: unit * 0.52,
      arrowIconSize: unit * 0.58,
      labelFontSize: (unit * 0.34).clamp(10.0, 13.0).toDouble(),
    );
  }
}

class _PaginationSlot {
  const _PaginationSlot.page(this.page) : isDots = false;
  const _PaginationSlot.dots() : page = null, isDots = true;

  final int? page;
  final bool isDots;
}

List<_PaginationSlot> _buildSlots(
  int currentPage,
  int totalPages,
  double availableWidth,
) {
  final density = _PaginationDensity.fromWidth(availableWidth);

  if (density == _PaginationDensity.minimal) {
    return [_PaginationSlot.page(currentPage)];
  }

  if (density == _PaginationDensity.compact && totalPages > 3) {
    return _buildCompactSlots(currentPage, totalPages);
  }

  if (totalPages <= 7) {
    return [
      for (var page = 1; page <= totalPages; page++) _PaginationSlot.page(page),
    ];
  }

  if (currentPage <= 4) {
    return [
      const _PaginationSlot.page(1),
      const _PaginationSlot.page(2),
      const _PaginationSlot.page(3),
      const _PaginationSlot.page(4),
      const _PaginationSlot.page(5),
      const _PaginationSlot.dots(),
      _PaginationSlot.page(totalPages),
    ];
  }

  if (currentPage >= totalPages - 3) {
    return [
      const _PaginationSlot.page(1),
      const _PaginationSlot.dots(),
      _PaginationSlot.page(totalPages - 4),
      _PaginationSlot.page(totalPages - 3),
      _PaginationSlot.page(totalPages - 2),
      _PaginationSlot.page(totalPages - 1),
      _PaginationSlot.page(totalPages),
    ];
  }

  return [
    const _PaginationSlot.page(1),
    const _PaginationSlot.dots(),
    _PaginationSlot.page(currentPage - 1),
    _PaginationSlot.page(currentPage),
    _PaginationSlot.page(currentPage + 1),
    const _PaginationSlot.dots(),
    _PaginationSlot.page(totalPages),
  ];
}

List<_PaginationSlot> _buildCompactSlots(int currentPage, int totalPages) {
  if (totalPages <= 3) {
    return [
      for (var page = 1; page <= totalPages; page++) _PaginationSlot.page(page),
    ];
  }

  if (currentPage <= 2) {
    return [
      const _PaginationSlot.page(1),
      const _PaginationSlot.page(2),
      const _PaginationSlot.page(3),
    ];
  }

  if (currentPage >= totalPages - 1) {
    return [
      _PaginationSlot.page(totalPages - 2),
      _PaginationSlot.page(totalPages - 1),
      _PaginationSlot.page(totalPages),
    ];
  }

  return [
    _PaginationSlot.page(currentPage - 1),
    _PaginationSlot.page(currentPage),
    _PaginationSlot.page(currentPage + 1),
  ];
}

enum _PaginationDensity {
  minimal,
  compact,
  full;

  factory _PaginationDensity.fromWidth(double width) {
    if (width < 300) {
      return _PaginationDensity.minimal;
    }

    if (width < 420) {
      return _PaginationDensity.compact;
    }

    return _PaginationDensity.full;
  }
}

class _PaginationSlotWidget extends StatelessWidget {
  const _PaginationSlotWidget({
    required this.slot,
    required this.currentPage,
    required this.totalPages,
    required this.metrics,
    required this.onPageChanged,
  });

  final _PaginationSlot slot;
  final int currentPage;
  final int totalPages;
  final _PaginationMetrics metrics;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (slot.isDots) {
      return SizedBox(
        width: metrics.dotWidth,
        height: metrics.pageSize,
        child: Center(
          child: Text(
            '...',
            style: AppTextStyle(
              color: AppPalette.warmSurfaceHigh16,
              fontSize: metrics.dotsFontSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      );
    }

    final page = slot.page!;
    final selected = page == currentPage;
    final l10n = AppLocalizations.of(context);
    final label =
        l10n?.commonPaginationLabel(page, totalPages) ??
        'Page $page of $totalPages';

    if (selected) {
      return _ActivePageButton(
        page: page,
        metrics: metrics,
        semanticLabel: label,
      );
    }

    return _RoundPaginationButton(
      size: metrics.pageSize,
      background: AppPalette.warmSurface25,
      border: AppPalette.warmSurfaceHigh07,
      semanticLabel: label,
      onTap: onPageChanged == null ? null : () => onPageChanged!(page),
      child: _PaginationNumber(
        page: page,
        color: AppPalette.orangeLight23,
        fontSize: metrics.numberFontSize,
      ),
    );
  }
}

class _ActivePageButton extends StatelessWidget {
  const _ActivePageButton({
    required this.page,
    required this.metrics,
    required this.semanticLabel,
  });

  final int page;
  final _PaginationMetrics metrics;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: true,
      label: semanticLabel,
      child: SizedBox(
        width: metrics.activeOuterSize,
        height: metrics.activeOuterSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size.square(metrics.activeOuterSize),
              painter: const _ActivePageGlowPainter(),
            ),
            Container(
              width: metrics.activeSize,
              height: metrics.activeSize,
              alignment: Alignment.center,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(0, -0.24),
                  radius: 0.82,
                  colors: [
                    AppPalette.warmMuted47,
                    AppPalette.warmMuted43,
                    AppPalette.warmMuted41,
                  ],
                  stops: [0.0, 0.64, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.warmMuted43.withValues(alpha: 0.92),
                    blurRadius: metrics.activeSize * 0.3,
                  ),
                  BoxShadow(
                    color: AppPalette.warmMuted39.withValues(alpha: 0.72),
                    blurRadius: metrics.activeSize * 0.52,
                  ),
                  BoxShadow(
                    color: AppPalette.white.withValues(alpha: 0.30),
                    blurRadius: metrics.activeSize * 0.74,
                  ),
                ],
              ),
              child: _PaginationNumber(
                page: page,
                color: AppPalette.white,
                fontSize: metrics.activeNumberFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationArrowButton extends StatelessWidget {
  const _PaginationArrowButton({
    required this.direction,
    required this.metrics,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  final _PaginationArrowDirection direction;
  final _PaginationMetrics metrics;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = direction == _PaginationArrowDirection.previous
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: _RoundPaginationButton(
        size: metrics.arrowSize,
        background: AppPalette.warmSurface25,
        semanticLabel: tooltip,
        onTap: enabled ? onTap : null,
        child: Icon(
          icon,
          color: AppPalette.orangeLight23,
          size: metrics.arrowIconSize,
        ),
      ),
    );
  }
}

enum _PaginationArrowDirection { previous, next }

class _RoundPaginationButton extends StatelessWidget {
  const _RoundPaginationButton({
    required this.size,
    required this.background,
    required this.child,
    this.border,
    this.semanticLabel,
    this.onTap,
  });

  static const double _minTouchTargetSize = 44;

  final double size;
  final Color background;
  final Color? border;
  final Widget child;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hitTargetSize = math.max(size, _minTouchTargetSize);
    final button = Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: hitTargetSize,
          child: Center(
            child: Ink(
              width: size,
              height: size,
              decoration: AppBoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: border == null
                    ? null
                    : Border.all(color: border!, width: size * 0.035),
                boxShadow: border == null
                    ? null
                    : [
                        BoxShadow(
                          color: AppPalette.black.withValues(alpha: 0.35),
                          blurRadius: 0,
                          spreadRadius: size * 0.018,
                        ),
                      ],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );

    return Tooltip(
      message: semanticLabel ?? '',
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticLabel,
        child: button,
      ),
    );
  }
}

class _PaginationNumber extends StatelessWidget {
  const _PaginationNumber({
    required this.page,
    required this.color,
    required this.fontSize,
  });

  final int page;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = page >= 100 ? fontSize * 0.82 : fontSize;

    return Padding(
      padding: AppEdgeInsets.all(fontSize * 0.08),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$page',
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTextStyle(
            color: color,
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PaginationLabel extends StatelessWidget {
  const _PaginationLabel({
    required this.currentPage,
    required this.totalPages,
    required this.metrics,
  });

  final int currentPage;
  final int totalPages;
  final _PaginationMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)?.localeName.split('_').first;
    final baseStyle = AppTextStyle(
      color: AppPalette.warmSurfaceHigh16,
      fontSize: metrics.labelFontSize,
      fontWeight: FontWeight.w900,
      height: 1.2,
    );
    final accentStyle = baseStyle.copyWith(color: AppPalette.primary);

    final spans = switch (locale) {
      'ru' => <InlineSpan>[
        TextSpan(text: 'СТРАНИЦА ', style: baseStyle),
        TextSpan(text: '$currentPage', style: accentStyle),
        TextSpan(text: ' ИЗ $totalPages', style: baseStyle),
      ],
      'kk' => <InlineSpan>[
        TextSpan(text: '$totalPages БЕТТІҢ ', style: baseStyle),
        TextSpan(text: '$currentPage', style: accentStyle),
        TextSpan(text: '-БЕТІ', style: baseStyle),
      ],
      _ => <InlineSpan>[
        TextSpan(text: 'PAGE ', style: baseStyle),
        TextSpan(text: '$currentPage', style: accentStyle),
        TextSpan(text: ' OF $totalPages', style: baseStyle),
      ],
    };

    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ActivePageGlowPainter extends CustomPainter {
  const _ActivePageGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppPalette.white.withValues(alpha: 0.55),
          AppPalette.warmMuted40.withValues(alpha: 0.35),
          AppPalette.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius, glowPaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dotCount = math.max(1, (size.shortestSide * 0.42).round());
    for (var i = 0; i < dotCount; i++) {
      final angle = i * 0.82;
      final distance = radius * (0.68 + (i % 5) * 0.075);
      final point = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final isWarm = i.isEven;
      dotPaint.color = isWarm
          ? AppPalette.warmMuted40.withValues(alpha: 0.72)
          : AppPalette.white.withValues(alpha: 0.62);
      canvas.drawCircle(
        point,
        size.shortestSide * (i % 3 == 0 ? 0.018 : 0.013),
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivePageGlowPainter oldDelegate) => false;
}
