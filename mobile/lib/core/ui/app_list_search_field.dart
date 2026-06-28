import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

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
      decoration: AppBoxDecoration(
        color: AppPalette.surfaceRaised,
        borderRadius: AppBorderRadius.circular(21),
      ),
      padding: const AppEdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppPalette.primary, size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: textFieldKey,
              controller: controller,
              focusNode: focusNode,
              onSubmitted: onSubmitted,
              onTapOutside: onTapOutside,
              textInputAction: TextInputAction.search,
              cursorColor: AppPalette.primary,
              style: const AppTextStyle(
                color: AppPalette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              decoration: AppInputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const AppTextStyle(color: AppPalette.orangeMuted02),
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
                    foregroundColor: AppPalette.orangeMuted02,
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
                    backgroundColor: AppPalette.primary.withValues(alpha: 0.12),
                    foregroundColor: AppPalette.primary,
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
                      key: const ValueKey(
                        'app-list-search-active-filter-count',
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const AppEdgeInsets.symmetric(horizontal: 4),
                      decoration: AppBoxDecoration(
                        color: AppPalette.primary,
                        borderRadius: AppBorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        activeFilterCount.toString(),
                        style: const AppTextStyle(
                          color: AppPalette.white,
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
