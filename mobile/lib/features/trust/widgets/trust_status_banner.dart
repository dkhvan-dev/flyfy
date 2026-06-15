import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';

enum TrustStatusBannerKind { blocked, muted, pendingAppeal, rejected }

class TrustStatusBanner extends StatelessWidget {
  const TrustStatusBanner({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final TrustStatusBannerKind kind;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = _TrustStatusBannerColors.forKind(kind);
    final icon = switch (kind) {
      TrustStatusBannerKind.blocked => Icons.block_outlined,
      TrustStatusBannerKind.muted => Icons.notifications_off_outlined,
      TrustStatusBannerKind.pendingAppeal => Icons.hourglass_top_outlined,
      TrustStatusBannerKind.rejected => Icons.gpp_bad_outlined,
    };
    final trimmedAction = (actionLabel ?? '').trim();

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.foreground, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TrustStatusBannerCopy(title: title, message: message),
                        if (trimmedAction.isNotEmpty && onAction != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                              ),
                              child: TextButton(
                                onPressed: onAction,
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.foreground,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(48, 40),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  trimmedAction,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustStatusBannerCopy extends StatelessWidget {
  const _TrustStatusBannerCopy({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TrustStatusBannerColors {
  const _TrustStatusBannerColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;

  static _TrustStatusBannerColors forKind(TrustStatusBannerKind kind) {
    return switch (kind) {
      TrustStatusBannerKind.blocked => _TrustStatusBannerColors(
        background: AppColors.destructive.withValues(alpha: 0.12),
        border: AppColors.destructive.withValues(alpha: 0.45),
        foreground: AppColors.destructive,
      ),
      TrustStatusBannerKind.muted => _TrustStatusBannerColors(
        background: AppColors.surfaceLight,
        border: AppColors.border,
        foreground: AppColors.textSecondary,
      ),
      TrustStatusBannerKind.pendingAppeal => _TrustStatusBannerColors(
        background: AppColors.accent.withValues(alpha: 0.12),
        border: AppColors.accent.withValues(alpha: 0.42),
        foreground: AppColors.accent,
      ),
      TrustStatusBannerKind.rejected => _TrustStatusBannerColors(
        background: const Color(0xFFB45309).withValues(alpha: 0.12),
        border: const Color(0xFFB45309).withValues(alpha: 0.42),
        foreground: const Color(0xFFB45309),
      ),
    };
  }
}
