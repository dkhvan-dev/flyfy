import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

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
    final colors = AppDesignSystem.colorsFor(context);
    final bannerColors = _TrustStatusBannerColors.forKind(colors, kind);
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
        decoration: AppBoxDecoration(
          color: bannerColors.background,
          border: Border.all(color: bannerColors.border),
          borderRadius: AppBorderRadius.circular(8),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: bannerColors.foreground, size: 22),
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
                                  foregroundColor: bannerColors.foreground,
                                  padding: const AppEdgeInsets.symmetric(
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
    final colors = AppDesignSystem.colorsFor(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
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

  static _TrustStatusBannerColors forKind(
    AppColors colors,
    TrustStatusBannerKind kind,
  ) {
    return switch (kind) {
      TrustStatusBannerKind.blocked => _TrustStatusBannerColors(
        background: colors.danger.withValues(alpha: 0.12),
        border: colors.danger.withValues(alpha: 0.45),
        foreground: colors.danger,
      ),
      TrustStatusBannerKind.muted => _TrustStatusBannerColors(
        background: colors.surfaceHigh,
        border: colors.border,
        foreground: colors.textSecondary,
      ),
      TrustStatusBannerKind.pendingAppeal => _TrustStatusBannerColors(
        background: colors.primary.withValues(alpha: 0.12),
        border: colors.primary.withValues(alpha: 0.42),
        foreground: colors.primary,
      ),
      TrustStatusBannerKind.rejected => _TrustStatusBannerColors(
        background: colors.warning.withValues(alpha: 0.12),
        border: colors.warning.withValues(alpha: 0.42),
        foreground: colors.warning,
      ),
    };
  }
}
