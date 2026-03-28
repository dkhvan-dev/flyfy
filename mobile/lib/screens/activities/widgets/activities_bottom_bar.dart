import 'package:flutter/material.dart';

enum ActivitiesBottomBarBackgroundStyle { discover, home }

class ActivitiesBottomBar extends StatelessWidget {
  const ActivitiesBottomBar({
    super.key,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onCreateTap,
    required this.onServicesTap,
    required this.onChatsTap,
    this.backgroundStyle = ActivitiesBottomBarBackgroundStyle.discover,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback onCreateTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;
  final ActivitiesBottomBarBackgroundStyle backgroundStyle;

  @override
  Widget build(BuildContext context) {
    final layout = _ActivitiesBottomBarLayout.of(context);
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final useHomeBackground =
        backgroundStyle == ActivitiesBottomBarBackgroundStyle.home;

    return SizedBox(
      height: layout.totalHeight + safeBottomInset,
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottomInset),
        child: SizedBox(
          height: layout.barHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: useHomeBackground
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF4A321A), Color(0xFF3A2816)],
                          ),
                    color: useHomeBackground ? const Color(0xF52A1A0C) : null,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(
                          alpha: useHomeBackground ? 0.05 : 0.04,
                        ),
                      ),
                    ),
                    boxShadow: useHomeBackground
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 26,
                              offset: const Offset(0, -10),
                            ),
                          ],
                  ),
                ),
              ),
              if (!useHomeBackground)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -1.42),
                          radius: 0.56,
                          colors: [
                            const Color(0xFFFF9800).withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.36],
                        ),
                      ),
                    ),
                  ),
                ),
              if (!useHomeBackground)
                Positioned(
                  top: 1,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.02),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.horizontalPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActivitiesBottomBarItem(
                        label: 'Home',
                        iconKind: _ActivitiesBottomBarIconKind.home,
                        layout: layout,
                        onTap: onHomeTap,
                      ),
                    ),
                    Expanded(
                      child: _ActivitiesBottomBarItem(
                        label: 'QR',
                        iconKind: _ActivitiesBottomBarIconKind.qr,
                        layout: layout,
                        onTap: onQrTap,
                      ),
                    ),
                    SizedBox(
                      width: layout.centerSlotWidth,
                      child: Center(
                        child: _ActivitiesBottomBarFab(
                          layout: layout,
                          onTap: onCreateTap,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ActivitiesBottomBarItem(
                        label: 'Services',
                        iconKind: _ActivitiesBottomBarIconKind.services,
                        layout: layout,
                        onTap: onServicesTap,
                      ),
                    ),
                    Expanded(
                      child: _ActivitiesBottomBarItem(
                        label: 'Chats',
                        iconKind: _ActivitiesBottomBarIconKind.chats,
                        layout: layout,
                        onTap: onChatsTap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivitiesBottomBarItem extends StatelessWidget {
  const _ActivitiesBottomBarItem({
    required this.label,
    required this.iconKind,
    required this.layout,
    required this.onTap,
  });

  final String label;
  final _ActivitiesBottomBarIconKind iconKind;
  final _ActivitiesBottomBarLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE6CFB2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFFFF9800).withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: layout.barHeight,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout.itemInnerPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActivitiesBottomBarVectorIcon(
                    kind: iconKind,
                    size: layout.iconSize,
                    color: color,
                    strokeWidth: layout.iconStrokeWidth,
                  ),
                  SizedBox(height: layout.itemGap),
                  SizedBox(
                    height: layout.labelHeight,
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: layout.labelSize,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
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

enum _ActivitiesBottomBarIconKind { home, qr, services, chats }

class _ActivitiesBottomBarVectorIcon extends StatelessWidget {
  const _ActivitiesBottomBarVectorIcon({
    required this.kind,
    required this.size,
    required this.color,
    required this.strokeWidth,
  });

  final _ActivitiesBottomBarIconKind kind;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ActivitiesBottomBarIconPainter(
          kind: kind,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _ActivitiesBottomBarIconPainter extends CustomPainter {
  const _ActivitiesBottomBarIconPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  final _ActivitiesBottomBarIconKind kind;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double sx(num value) => value / 24 * size.width;
    double sy(num value) => value / 24 * size.height;

    switch (kind) {
      case _ActivitiesBottomBarIconKind.home:
        final roof = Path()
          ..moveTo(sx(4), sy(10.5))
          ..lineTo(sx(12), sy(4))
          ..lineTo(sx(20), sy(10.5));
        final body = Path()
          ..moveTo(sx(7), sy(9.5))
          ..lineTo(sx(7), sy(19))
          ..lineTo(sx(10.5), sy(19))
          ..lineTo(sx(10.5), sy(14))
          ..lineTo(sx(13.5), sy(14))
          ..lineTo(sx(13.5), sy(19))
          ..lineTo(sx(17), sy(19))
          ..lineTo(sx(17), sy(9.5));
        canvas.drawPath(roof, paint);
        canvas.drawPath(body, paint);
        return;

      case _ActivitiesBottomBarIconKind.qr:
        void drawSquare(double left, double top) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(sx(left), sy(top), sx(5), sy(5)),
              Radius.circular(sx(0.2)),
            ),
            paint,
          );
        }

        drawSquare(4, 4);
        drawSquare(15, 4);
        drawSquare(4, 15);

        void drawLine(double x1, double y1, double x2, double y2) {
          canvas.drawLine(
            Offset(sx(x1), sy(y1)),
            Offset(sx(x2), sy(y2)),
            paint,
          );
        }

        drawLine(16, 15, 16, 17);
        drawLine(20, 15, 20, 20);
        drawLine(15, 20, 18, 20);
        drawLine(8, 12, 10, 12);
        drawLine(12, 4, 12, 6);
        drawLine(12, 9, 12, 11);
        drawLine(12, 13, 12, 15);
        drawLine(10, 12, 12, 12);
        drawLine(14, 12, 16, 12);
        drawLine(18, 12, 20, 12);
        return;

      case _ActivitiesBottomBarIconKind.services:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(sx(4), sy(7), sx(20), sy(19)),
            Radius.circular(sx(2)),
          ),
          paint,
        );
        final handle = Path()
          ..moveTo(sx(8), sy(7))
          ..lineTo(sx(8), sy(5.5))
          ..quadraticBezierTo(sx(8), sy(4), sx(9.5), sy(4))
          ..lineTo(sx(14.5), sy(4))
          ..quadraticBezierTo(sx(16), sy(4), sx(16), sy(5.5))
          ..lineTo(sx(16), sy(7));
        canvas.drawPath(handle, paint);
        canvas.drawLine(Offset(sx(4), sy(12)), Offset(sx(20), sy(12)), paint);
        return;

      case _ActivitiesBottomBarIconKind.chats:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(sx(3), sy(5), sx(21), sy(16)),
            Radius.circular(sx(2)),
          ),
          paint,
        );
        final tail = Path()
          ..moveTo(sx(10), sy(16))
          ..lineTo(sx(5), sy(20))
          ..lineTo(sx(5), sy(16));
        canvas.drawPath(tail, paint);
        return;
    }
  }

  @override
  bool shouldRepaint(covariant _ActivitiesBottomBarIconPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _ActivitiesBottomBarFab extends StatelessWidget {
  const _ActivitiesBottomBarFab({required this.layout, required this.onTap});

  final _ActivitiesBottomBarLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = MaterialLocalizations.of(context).moreButtonTooltip;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox.square(
        dimension: layout.centerSlotWidth,
        child: Center(
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.08),
              highlightColor: Colors.transparent,
              child: Ink(
                width: layout.fabSize,
                height: layout.fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFAB26), Color(0xFFF79100)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF241408),
                    width: layout.fabBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.03),
                      blurRadius: 0,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: layout.fabIconSize,
                    child: CustomPaint(
                      painter: _ActivitiesBottomBarFabIconPainter(
                        color: const Color(0xFFFFF8EE),
                        strokeWidth: layout.fabIconStrokeWidth,
                      ),
                    ),
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

class _ActivitiesBottomBarFabIconPainter extends CustomPainter {
  const _ActivitiesBottomBarFabIconPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double sx(num value) => value / 24 * size.width;
    double sy(num value) => value / 24 * size.height;

    canvas.drawLine(Offset(sx(12), sy(5)), Offset(sx(12), sy(19)), paint);
    canvas.drawLine(Offset(sx(5), sy(12)), Offset(sx(19), sy(12)), paint);
  }

  @override
  bool shouldRepaint(covariant _ActivitiesBottomBarFabIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _ActivitiesBottomBarLayout {
  const _ActivitiesBottomBarLayout._({
    required this.totalHeight,
    required this.barHeight,
    required this.horizontalPadding,
    required this.centerSlotWidth,
    required this.iconSize,
    required this.iconStrokeWidth,
    required this.labelSize,
    required this.itemGap,
    required this.itemInnerPadding,
    required this.labelHeight,
    required this.fabSize,
    required this.fabBorderWidth,
    required this.fabIconSize,
    required this.fabIconStrokeWidth,
  });

  factory _ActivitiesBottomBarLayout.of(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final widthScale = (screenWidth / 393).clamp(0.92, 1.0).toDouble();
    final textAdjustment = textScale > 1.08 ? 0.96 : 1.0;
    final scale = (widthScale * textAdjustment).clamp(0.90, 1.0).toDouble();

    double s(double value) => value * scale;

    return _ActivitiesBottomBarLayout._(
      totalHeight: s(78),
      barHeight: s(78),
      horizontalPadding: s(4),
      centerSlotWidth: s(84),
      iconSize: s(30),
      iconStrokeWidth: s(2),
      labelSize: s(10),
      itemGap: s(5),
      itemInnerPadding: s(2),
      labelHeight: s(10),
      fabSize: s(46),
      fabBorderWidth: s(4),
      fabIconSize: s(22),
      fabIconStrokeWidth: s(2.4),
    );
  }

  final double totalHeight;
  final double barHeight;
  final double horizontalPadding;
  final double centerSlotWidth;
  final double iconSize;
  final double iconStrokeWidth;
  final double labelSize;
  final double itemGap;
  final double itemInnerPadding;
  final double labelHeight;
  final double fabSize;
  final double fabBorderWidth;
  final double fabIconSize;
  final double fabIconStrokeWidth;
}
