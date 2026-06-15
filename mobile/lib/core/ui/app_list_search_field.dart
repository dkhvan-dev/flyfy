import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppListSearchField extends StatelessWidget {
  const AppListSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.filterTooltip,
    required this.onFilterTap,
    this.focusNode,
    this.activeFilterCount = 0,
    this.showClearButton = false,
    this.onClear,
    this.onSubmitted,
    this.onTapOutside,
    this.textFieldKey,
  });

  final TextEditingController controller;
  final Key? textFieldKey;
  final FocusNode? focusNode;
  final String hintText;
  final String filterTooltip;
  final VoidCallback onFilterTap;
  final int activeFilterCount;
  final bool showClearButton;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1F14),
        borderRadius: BorderRadius.circular(21),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.accent, size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: textFieldKey,
              controller: controller,
              focusNode: focusNode,
              onSubmitted: onSubmitted,
              onTapOutside: onTapOutside,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.accent,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
              ),
            ),
          ),
          if (showClearButton)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.trim().isEmpty) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip.toLowerCase(),
                  onPressed: onClear ?? controller.clear,
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF9F8B7D),
                    minimumSize: const Size(36, 36),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                );
              },
            ),
          Tooltip(
            message: filterTooltip,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: filterTooltip,
                  onPressed: onFilterTap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    foregroundColor: AppColors.accent,
                    minimumSize: const Size(43, 43),
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 24),
                ),
                if (activeFilterCount > 0)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        activeFilterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
