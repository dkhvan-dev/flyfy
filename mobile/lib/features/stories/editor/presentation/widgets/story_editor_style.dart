import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

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
    primary: AppPalette.primary,
    onPrimary: AppPalette.textPrimary,
    primaryContainer: AppPalette.primary.withValues(alpha: 0.22),
    onPrimaryContainer: AppPalette.textPrimary,
    secondary: AppPalette.primary,
    onSecondary: AppPalette.textPrimary,
    secondaryContainer: AppPalette.primary.withValues(alpha: 0.16),
    onSecondaryContainer: AppPalette.textPrimary,
    tertiary: AppPalette.primary,
    onTertiary: AppPalette.textPrimary,
    surface: StoryPalette.surface,
    onSurface: AppPalette.textPrimary,
    surfaceContainerHighest: StoryPalette.surfaceRaised,
    outline: AppPalette.outlineOverlay,
    outlineVariant: AppPalette.outlineOverlayLight,
  );
  final border = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: BorderSide(color: AppPalette.outlineOverlay),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: const BorderSide(color: AppPalette.primary, width: 1.4),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    dividerColor: AppPalette.outlineOverlay,
    splashColor: AppPalette.primary.withValues(alpha: 0.10),
    highlightColor: AppPalette.primary.withValues(alpha: 0.08),
    textSelectionTheme: base.textSelectionTheme.copyWith(
      cursorColor: AppPalette.primary,
      selectionColor: AppPalette.primary.withValues(alpha: 0.28),
      selectionHandleColor: AppPalette.primary,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: AppPalette.surfaceCoolLight,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      border: border,
      labelStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppPalette.textCoolSecondary,
      ),
      floatingLabelStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppPalette.primary,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppPalette.textCaption,
      ),
      suffixIconColor: AppPalette.primary,
      prefixIconColor: AppPalette.primary,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: StoryPalette.surfaceRaised,
      surfaceTintColor: AppPalette.transparent,
      textStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppPalette.textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.textPrimary,
        disabledBackgroundColor: AppPalette.primary.withValues(alpha: 0.18),
        disabledForegroundColor: AppPalette.textCaption,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.primary,
        disabledForegroundColor: AppPalette.textCaption,
        side: BorderSide(color: AppPalette.primary.withValues(alpha: 0.58)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.primary,
        disabledForegroundColor: AppPalette.textCaption,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppPalette.primary,
        disabledForegroundColor: AppPalette.textCaption,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.textPrimary;
          }
          return AppPalette.primary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary;
          }
          return AppPalette.primary.withValues(alpha: 0.10);
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppPalette.primary.withValues(alpha: 0.46)),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppPalette.primary.withValues(alpha: 0.12),
      selectedColor: AppPalette.primary.withValues(alpha: 0.24),
      disabledColor: AppPalette.surfaceCoolLight,
      labelStyle: base.textTheme.bodySmall?.copyWith(
        color: AppPalette.textPrimary,
      ),
      secondaryLabelStyle: base.textTheme.bodySmall?.copyWith(
        color: AppPalette.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppPalette.primary),
      side: BorderSide(color: AppPalette.outlineOverlay),
    ),
  );
}

BoxDecoration storyEditorPanelDecoration(BuildContext context) {
  return AppBoxDecoration(
    color: AppPalette.surfaceCoolLight,
    border: Border.all(color: AppPalette.outlineOverlay),
    borderRadius: AppBorderRadius.circular(8),
  );
}

InputDecoration storyEditorInputDecoration({
  required String label,
  String? hint,
  Widget? suffixIcon,
  String? errorText,
}) {
  final errorBorder = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(8),
    borderSide: const BorderSide(color: AppPalette.danger, width: 1.4),
  );
  return AppInputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    errorText: errorText,
    errorMaxLines: 2,
    filled: true,
    fillColor: AppPalette.surfaceCoolLight,
    border: OutlineInputBorder(borderRadius: AppBorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.circular(8),
      borderSide: BorderSide(color: AppPalette.outlineOverlay),
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
