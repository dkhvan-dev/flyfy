import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppBoxDecoration(
        color: colors.primary.withValues(alpha: 0.14),
        border: Border.all(color: colors.borderPrimary),
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
