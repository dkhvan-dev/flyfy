import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../../../l10n/generated/app_localizations.dart';
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
  final colors = AppDesignSystem.colorsFor(context);
  final colorScheme = base.colorScheme.copyWith(
    primary: colors.primary,
    onPrimary: colors.textPrimary,
    primaryContainer: colors.primaryContainer,
    onPrimaryContainer: colors.textPrimary,
    secondary: colors.secondary,
    onSecondary: colors.onSecondary,
    secondaryContainer: colors.secondaryContainer,
    onSecondaryContainer: colors.onSecondary,
    tertiary: colors.secondarySoft,
    onTertiary: colors.onSecondary,
    error: colors.danger,
    onError: colors.textPrimary,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    surfaceContainerHighest: colors.surfaceRaised,
    outline: colors.border,
    outlineVariant: colors.borderSoft,
  );
  final border = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: BorderSide(color: colors.border),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: BorderSide(color: colors.primary, width: 1.4),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    dividerColor: colors.borderSoft,
    splashColor: colors.primary.withValues(alpha: 0.10),
    highlightColor: colors.primary.withValues(alpha: 0.08),
    textSelectionTheme: base.textSelectionTheme.copyWith(
      cursorColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: 0.28),
      selectionHandleColor: colors.primary,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: colors.surfaceRaised,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      border: border,
      labelStyle: base.textTheme.bodyMedium?.copyWith(
        color: colors.textSecondary,
      ),
      floatingLabelStyle: base.textTheme.bodyMedium?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: base.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
      suffixIconColor: colors.primary,
      prefixIconColor: colors.primary,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: colors.surfaceRaised,
      surfaceTintColor: colors.transparent,
      textStyle: base.textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        disabledBackgroundColor: colors.surfaceHigh,
        disabledForegroundColor: colors.textDisabled,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.textDisabled,
        side: BorderSide(color: colors.borderPrimary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.textDisabled,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.textDisabled,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.onPrimary;
          }
          return colors.primary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.primary.withValues(alpha: 0.10);
        }),
        side: WidgetStatePropertyAll(BorderSide(color: colors.borderPrimary)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colors.primary.withValues(alpha: 0.12),
      selectedColor: colors.primary.withValues(alpha: 0.24),
      disabledColor: colors.surfaceRaised,
      labelStyle: base.textTheme.bodySmall?.copyWith(color: colors.textPrimary),
      secondaryLabelStyle: base.textTheme.bodySmall?.copyWith(
        color: colors.textPrimary,
      ),
      iconTheme: IconThemeData(color: colors.primary),
      side: BorderSide(color: colors.borderSoft),
    ),
  );
}

BoxDecoration storyEditorPanelDecoration(BuildContext context) {
  final colors = AppDesignSystem.colorsFor(context);
  return AppBoxDecoration(
    color: colors.surface,
    border: Border.all(color: colors.border),
    borderRadius: AppBorderRadius.circular(8),
  );
}

InputDecoration storyEditorInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  Widget? suffixIcon,
  String? errorText,
}) {
  final colors = AppDesignSystem.colorsFor(context);
  final enabledBorder = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: BorderSide(color: colors.border),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: BorderSide(color: colors.primary, width: 1.4),
  );
  final errorBorder = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: BorderSide(color: colors.danger, width: 1.4),
  );
  return AppInputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    errorText: errorText,
    errorMaxLines: 2,
    filled: true,
    fillColor: colors.surfaceRaised,
    border: enabledBorder,
    enabledBorder: enabledBorder,
    focusedBorder: focusedBorder,
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
