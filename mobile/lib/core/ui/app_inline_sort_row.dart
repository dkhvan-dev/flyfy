import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppInlineSortOption<T> {
  const AppInlineSortOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppInlineSortRow<T> extends StatelessWidget {
  const AppInlineSortRow({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.isAscending,
    required this.onSelected,
    this.fontSize = 12,
    this.iconSize = 14,
    this.labelToOptionsGap = 18,
    this.optionGap = 22,
    this.iconGap = 5,
    this.verticalPadding = 8,
    this.minItemHeight = 40,
    this.letterSpacing = 1.4,
    this.wrap = false,
    this.labelColor = const Color(0xC7E3D4C2),
    this.activeColor = AppColors.accent,
    this.inactiveColor = const Color(0xFFA98D74),
  });

  final String label;
  final List<AppInlineSortOption<T>> options;
  final T selectedValue;
  final bool isAscending;
  final ValueChanged<T> onSelected;
  final double fontSize;
  final double iconSize;
  final double labelToOptionsGap;
  final double optionGap;
  final double iconGap;
  final double verticalPadding;
  final double minItemHeight;
  final double letterSpacing;
  final bool wrap;
  final Color labelColor;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final directionIcon = isAscending
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    final labelWidget = Text(
      '$label:',
      style: TextStyle(
        color: labelColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
      ),
    );
    final optionWidgets = [
      for (final option in options)
        _InlineSortItem<T>(
          option: option,
          selected: selectedValue == option.value,
          directionIcon: directionIcon,
          onSelected: onSelected,
          fontSize: fontSize,
          iconSize: iconSize,
          iconGap: iconGap,
          verticalPadding: verticalPadding,
          minItemHeight: minItemHeight,
          letterSpacing: letterSpacing,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
        ),
    ];

    return wrap
        ? Wrap(
            spacing: optionGap,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [labelWidget, ...optionWidgets],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                labelWidget,
                SizedBox(width: labelToOptionsGap),
                for (final optionWidget in optionWidgets) ...[
                  optionWidget,
                  SizedBox(width: optionGap),
                ],
              ],
            ),
          );
  }
}

class _InlineSortItem<T> extends StatelessWidget {
  const _InlineSortItem({
    required this.option,
    required this.selected,
    required this.directionIcon,
    required this.onSelected,
    required this.fontSize,
    required this.iconSize,
    required this.iconGap,
    required this.verticalPadding,
    required this.minItemHeight,
    required this.letterSpacing,
    required this.activeColor,
    required this.inactiveColor,
  });

  final AppInlineSortOption<T> option;
  final bool selected;
  final IconData directionIcon;
  final ValueChanged<T> onSelected;
  final double fontSize;
  final double iconSize;
  final double iconGap;
  final double verticalPadding;
  final double minItemHeight;
  final double letterSpacing;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => onSelected(option.value),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minItemHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: letterSpacing,
                  ),
                ),
                if (selected) ...[
                  SizedBox(width: iconGap),
                  Icon(directionIcon, color: activeColor, size: iconSize),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
