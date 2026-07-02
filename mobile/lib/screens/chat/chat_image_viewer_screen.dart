import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class ChatImageViewerScreen extends StatelessWidget {
  const ChatImageViewerScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Scaffold(
      backgroundColor: colors.backgroundDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.75,
                maxScale: 4,
                child: Center(
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
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
