import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppBoxDecoration(
        color: AppPalette.tagBackground,
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const AppTextStyle(
          color: AppPalette.primaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
