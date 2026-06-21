import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';

class TripPreparationCta extends StatelessWidget {
  const TripPreparationCta({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2114),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.34)),
          ),
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? width - 84 : width - 156,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              height: 1.14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                iconAlignment: IconAlignment.end,
                label: Text(
                  actionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
