import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class ChatImageViewerScreen extends StatefulWidget {
  const ChatImageViewerScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ChatImageViewerScreen> createState() => _ChatImageViewerScreenState();
}

class _ChatImageViewerScreenState extends State<ChatImageViewerScreen> {
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 700.0;

  final _transformationController = TransformationController();
  double _dragOffset = 0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  double get _currentScale =>
      _transformationController.value.getMaxScaleOnAxis();

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_currentScale > 1.05) return;
    final delta = details.primaryDelta ?? details.delta.dy;
    if (delta == 0) return;

    setState(() => _dragOffset = math.max(0, _dragOffset + delta));
  }

  void _dismissBySwipeDown(DragEndDetails details) {
    if (_currentScale > 1.05) {
      _resetDragOffset();
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _dragOffset >= _dismissDistance || velocity >= _dismissVelocity;
    if (shouldDismiss) {
      Navigator.of(context).pop();
      return;
    }
    if (_dragOffset == 0) return;
    setState(() => _dragOffset = 0);
  }

  void _resetDragOffset() {
    if (_dragOffset == 0) return;
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final imageOpacity = (1 - (_dragOffset / 360)).clamp(0.62, 1.0);

    return Scaffold(
      backgroundColor: colors.backgroundDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: _handleVerticalDragUpdate,
                onVerticalDragEnd: _dismissBySwipeDown,
                onVerticalDragCancel: _resetDragOffset,
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Opacity(
                    opacity: imageOpacity.toDouble(),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.75,
                      maxScale: 4,
                      child: Center(
                        child: Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _ViewerIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerIconButton extends StatelessWidget {
  const _ViewerIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: AppBoxDecoration(
          shape: BoxShape.circle,
          color: colors.scrim.withValues(alpha: 0.46),
          border: Border.all(color: colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: colors.white, size: 24),
      ),
    );
  }
}
