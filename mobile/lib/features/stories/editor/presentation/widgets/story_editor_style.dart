import 'package:flutter/material.dart';

import '../../../../../core/ui/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../story_ui.dart';
import '../../domain/story_document.dart';

abstract final class StoryEditorSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class StoryEditorBreakpoints {
  static const compact = 600.0;
  static const expanded = 840.0;
}

ThemeData storyEditorTheme(BuildContext context) {
  final base = Theme.of(context);
  final colorScheme = base.colorScheme.copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.textPrimary,
    primaryContainer: AppColors.accent.withValues(alpha: 0.22),
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.accent,
    onSecondary: AppColors.textPrimary,
    secondaryContainer: AppColors.accent.withValues(alpha: 0.16),
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.textPrimary,
    surface: StoryPalette.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: StoryPalette.surfaceRaised,
    outline: AppColors.border,
    outlineVariant: AppColors.borderLight,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: AppColors.border),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    dividerColor: AppColors.border,
    splashColor: AppColors.accent.withValues(alpha: 0.10),
    highlightColor: AppColors.accent.withValues(alpha: 0.08),
    textSelectionTheme: base.textSelectionTheme.copyWith(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.28),
      selectionHandleColor: AppColors.accent,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: AppColors.surfaceLight,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      border: border,
      labelStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      floatingLabelStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.accent,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.textCaption,
      ),
      suffixIconColor: AppColors.accent,
      prefixIconColor: AppColors.accent,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: StoryPalette.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      textStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.18),
        disabledForegroundColor: AppColors.textCaption,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        disabledForegroundColor: AppColors.textCaption,
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.58)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        disabledForegroundColor: AppColors.textCaption,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.accent,
        disabledForegroundColor: AppColors.textCaption,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textPrimary;
          }
          return AppColors.accent;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.accent.withValues(alpha: 0.10);
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppColors.accent.withValues(alpha: 0.46)),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
      selectedColor: AppColors.accent.withValues(alpha: 0.24),
      disabledColor: AppColors.surfaceLight,
      labelStyle: base.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
      ),
      secondaryLabelStyle: base.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.accent),
      side: BorderSide(color: AppColors.border),
    ),
  );
}

BoxDecoration storyEditorPanelDecoration(BuildContext context) {
  return BoxDecoration(
    color: AppColors.surfaceLight,
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(8),
  );
}

InputDecoration storyEditorInputDecoration({
  required String label,
  String? hint,
  Widget? suffixIcon,
  String? errorText,
}) {
  final errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.destructive, width: 1.4),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    errorText: errorText,
    errorMaxLines: 2,
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border),
    ),
    errorBorder: errorBorder,
    focusedErrorBorder: errorBorder,
  );
}

String storyBlockTypeLabel(AppLocalizations l10n, StoryBlockType type) {
  return switch (type) {
    StoryBlockType.paragraph => l10n.storyEditorBlockParagraph,
    StoryBlockType.heading => l10n.storyEditorBlockHeading,
    StoryBlockType.bulletedList => l10n.storyEditorBlockList,
    StoryBlockType.numberedList => l10n.storyEditorBlockNumberedList,
    StoryBlockType.quote => l10n.storyEditorBlockQuote,
    StoryBlockType.callout => l10n.storyEditorBlockCallout,
    StoryBlockType.image => l10n.storyEditorBlockImage,
    StoryBlockType.gallery => l10n.storyEditorBlockGallery,
    StoryBlockType.divider => l10n.storyEditorBlockDivider,
    StoryBlockType.placeReference => l10n.storyEditorBlockPlaceReference,
    StoryBlockType.routeReference => l10n.storyEditorBlockRouteReference,
  };
}
