import 'package:flutter/material.dart';

import '../../../../../core/ui/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../story_ui.dart';
import 'story_editor_style.dart';

class StoryEditorToolbar extends StatelessWidget {
  const StoryEditorToolbar({
    super.key,
    required this.onAddBlock,
    required this.onHeading,
    required this.onList,
    required this.onQuote,
    required this.onImage,
    required this.onUndo,
    required this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  final VoidCallback onAddBlock;
  final VoidCallback onHeading;
  final VoidCallback onList;
  final VoidCallback onQuote;
  final VoidCallback onImage;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactToolbar = constraints.maxWidth < 390 || textScale > 1.25;
        final toolbarMinHeight = adaptive.scale(
          64,
          minFactor: 0.88,
          maxFactor: 1.04,
        );
        final dividerHeight = adaptive.scale(
          32,
          minFactor: 0.9,
          maxFactor: 1.04,
        );
        final dividerWidth = adaptive.scale(
          16,
          minFactor: 0.86,
          maxFactor: 1.04,
        );
        return Material(
          elevation: 16,
          color: StoryPalette.surface,
          child: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: toolbarMinHeight),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptive.scale(
                      12,
                      minFactor: 0.9,
                      maxFactor: 1.04,
                    ),
                    vertical: adaptive.scale(
                      8,
                      minFactor: 0.9,
                      maxFactor: 1.04,
                    ),
                  ),
                  child: Row(
                    children: [
                      _ToolbarButton(
                        label: l10n.storyEditorToolbarAddBlock,
                        icon: Icons.add_rounded,
                        onPressed: onAddBlock,
                        emphasized: true,
                        showLabel: !compactToolbar,
                      ),
                      _ToolbarButton(
                        label: l10n.storyEditorToolbarHeading,
                        icon: Icons.title_rounded,
                        onPressed: onHeading,
                      ),
                      _ToolbarButton(
                        label: l10n.storyEditorToolbarList,
                        icon: Icons.format_list_bulleted_rounded,
                        onPressed: onList,
                      ),
                      _ToolbarButton(
                        label: l10n.storyEditorToolbarQuote,
                        icon: Icons.format_quote_rounded,
                        onPressed: onQuote,
                      ),
                      _ToolbarButton(
                        label: l10n.storyEditorToolbarImage,
                        icon: Icons.image_outlined,
                        onPressed: onImage,
                      ),
                      SizedBox(
                        height: dividerHeight,
                        child: VerticalDivider(
                          width: dividerWidth,
                          color: StoryPalette.line,
                        ),
                      ),
                      _ToolbarButton(
                        label: l10n.storyEditorToolbarUndo,
                        icon: Icons.undo_rounded,
                        onPressed: canUndo ? onUndo : null,
                      ),
                      _ToolbarButton(
                        label: l10n.storyEditorToolbarRedo,
                        icon: Icons.redo_rounded,
                        onPressed: canRedo ? onRedo : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StoryEditorKeyboardFormattingToolbar extends StatelessWidget {
  const StoryEditorKeyboardFormattingToolbar({
    super.key,
    this.onInteractionStart,
    required this.onBold,
    required this.onItalic,
    required this.onStrikethrough,
    required this.onUnderline,
  });

  final VoidCallback? onInteractionStart;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrikethrough;
  final VoidCallback onUnderline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    return TextFieldTapRegion(
      child: Material(
        color: StoryPalette.surfaceRaised,
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: adaptive.scale(12, minFactor: 0.9, maxFactor: 1.04),
                vertical: adaptive.scale(8, minFactor: 0.9, maxFactor: 1.04),
              ),
              child: Row(
                children: [
                  _InlineFormatButton(
                    label: l10n.storyEditorToolbarBold,
                    onInteractionStart: onInteractionStart,
                    onPressed: onBold,
                  ),
                  _InlineFormatButton(
                    label: l10n.storyEditorToolbarItalic,
                    onInteractionStart: onInteractionStart,
                    onPressed: onItalic,
                  ),
                  _InlineFormatButton(
                    label: l10n.storyEditorToolbarStrikethrough,
                    onInteractionStart: onInteractionStart,
                    onPressed: onStrikethrough,
                  ),
                  _InlineFormatButton(
                    label: l10n.storyEditorToolbarUnderline,
                    onInteractionStart: onInteractionStart,
                    onPressed: onUnderline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineFormatButton extends StatelessWidget {
  const _InlineFormatButton({
    required this.label,
    required this.onPressed,
    this.onInteractionStart,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onInteractionStart;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final borderRadius = BorderRadius.circular(14);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        end: adaptive.scale(8, minFactor: 0.9, maxFactor: 1.04),
      ),
      child: Semantics(
        label: label,
        button: true,
        child: Material(
          color: AppColors.accent.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.24)),
          ),
          child: InkWell(
            canRequestFocus: false,
            borderRadius: borderRadius,
            onTapDown: (_) => onInteractionStart?.call(),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: adaptive.scale(44, minFactor: 1, maxFactor: 1.08),
                minHeight: adaptive.scale(40, minFactor: 1, maxFactor: 1.08),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: adaptive.scale(
                    14,
                    minFactor: 0.9,
                    maxFactor: 1.06,
                  ),
                  vertical: adaptive.scale(10, minFactor: 0.9, maxFactor: 1.06),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: StoryPalette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
    this.showLabel = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final foreground = onPressed == null
        ? AppColors.textCaption
        : AppColors.textPrimary;
    final background = emphasized
        ? AppColors.accent
        : AppColors.accent.withValues(alpha: onPressed == null ? 0.06 : 0.16);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: adaptive.scale(2, minFactor: 0.86, maxFactor: 1.04),
      ),
      child: Semantics(
        label: label,
        button: true,
        enabled: onPressed != null,
        child: showLabel
            ? FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: background,
                  foregroundColor: foreground,
                  disabledBackgroundColor: background,
                  disabledForegroundColor: foreground,
                  minimumSize: Size(
                    adaptive.scale(48, minFactor: 1, maxFactor: 1.08),
                    adaptive.scale(48, minFactor: 1, maxFactor: 1.08),
                  ),
                ),
                onPressed: onPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon),
                    SizedBox(width: StoryEditorSpacing.sm),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            : IconButton.filledTonal(
                tooltip: label,
                style: IconButton.styleFrom(
                  backgroundColor: background,
                  foregroundColor: foreground,
                  disabledBackgroundColor: background,
                  disabledForegroundColor: foreground,
                ),
                icon: Icon(icon),
                onPressed: onPressed,
              ),
      ),
    );
  }
}
