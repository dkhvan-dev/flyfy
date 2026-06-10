import 'package:flutter/material.dart';

import '../../../../../core/ui/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../domain/story_document.dart';
import 'story_editor_focus_visibility.dart';
import 'story_editor_style.dart';

class StoryTextBlock extends StatefulWidget {
  const StoryTextBlock({
    super.key,
    required this.block,
    required this.selected,
    required this.onChanged,
    required this.onFocus,
    required this.onDelete,
    this.onSelectionChanged,
    this.onTextInputFocused,
  });

  final StoryBlock block;
  final bool selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onFocus;
  final VoidCallback onDelete;
  final ValueChanged<TextSelection>? onSelectionChanged;
  final ValueChanged<BuildContext>? onTextInputFocused;

  @override
  State<StoryTextBlock> createState() => _StoryTextBlockState();
}

class _StoryTextBlockState extends State<StoryTextBlock> {
  late final _StoryTextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (_focusNode.hasFocus) {
          widget.onFocus();
          widget.onTextInputFocused?.call(context);
          _notifySelectionChanged();
        }
      });
    _textController = _StoryTextEditingController(block: widget.block)
      ..addListener(_notifySelectionChanged);
  }

  @override
  void didUpdateWidget(covariant StoryTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRefreshInlineStyle =
        oldWidget.block.id != widget.block.id ||
        oldWidget.block.type != widget.block.type ||
        oldWidget.block.marks != widget.block.marks;
    _textController.updateBlock(widget.block, notify: shouldRefreshInlineStyle);
    final nextText = widget.block.text ?? '';
    if (oldWidget.block.id != widget.block.id ||
        _textController.text != nextText) {
      _textController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.removeListener(_notifySelectionChanged);
    _textController.dispose();
    super.dispose();
  }

  void _notifySelectionChanged() {
    if (!_focusNode.hasFocus) return;
    final selection = _textController.selection;
    if (selection.isValid) {
      widget.onSelectionChanged?.call(selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.block.type;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = storyBlockTypeLabel(l10n, type);
    final textStyle = switch (type) {
      StoryBlockType.heading => theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      StoryBlockType.quote => theme.textTheme.bodyLarge?.copyWith(
        fontStyle: FontStyle.italic,
      ),
      StoryBlockType.callout => theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      _ => theme.textTheme.bodyLarge,
    };

    return DecoratedBox(
      decoration: storyEditorPanelDecoration(context).copyWith(
        border: Border.all(
          color: widget.selected ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StoryEditorSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  label: l10n.storyEditorDeleteBlockSemantic(
                    label.toLowerCase(),
                  ),
                  button: true,
                  child: IconButton(
                    tooltip: l10n.storyEditorDeleteBlockSemantic(
                      label.toLowerCase(),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: widget.onDelete,
                  ),
                ),
              ],
            ),
            StoryEditorRevealOnFocus(
              onFocus: widget.onTextInputFocused,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                minLines: type == StoryBlockType.heading ? 1 : 2,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: textStyle,
                decoration: InputDecoration(
                  hintText: _hintFor(l10n, type),
                  border: InputBorder.none,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintFor(AppLocalizations l10n, StoryBlockType type) {
    return switch (type) {
      StoryBlockType.heading => l10n.storyEditorTextHintHeading,
      StoryBlockType.bulletedList => l10n.storyEditorTextHintBulletedList,
      StoryBlockType.numberedList => l10n.storyEditorTextHintNumberedList,
      StoryBlockType.quote => l10n.storyEditorTextHintQuote,
      StoryBlockType.callout => l10n.storyEditorTextHintCallout,
      _ => l10n.storyEditorTextHintParagraph,
    };
  }
}

class _StoryTextEditingController extends TextEditingController {
  _StoryTextEditingController({required StoryBlock block})
    : _block = block,
      super(text: block.text ?? '');

  StoryBlock _block;

  void updateBlock(StoryBlock block, {required bool notify}) {
    _block = block;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = value.text;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final composing = value.composing;
    final hasComposing =
        withComposing &&
        composing.isValid &&
        composing.start >= 0 &&
        composing.end <= text.length &&
        composing.start < composing.end;
    final normalizedMarks = _normalizedMarks(text.length);
    if (text.isEmpty || (normalizedMarks.isEmpty && !hasComposing)) {
      return TextSpan(style: baseStyle, text: text);
    }

    final breakpoints = <int>{0, text.length};
    for (final mark in normalizedMarks) {
      breakpoints
        ..add(mark.start)
        ..add(mark.end);
    }
    if (hasComposing) {
      breakpoints
        ..add(composing.start)
        ..add(composing.end);
    }
    final sortedBreakpoints = breakpoints.toList(growable: false)..sort();
    final children = <TextSpan>[];
    for (var index = 0; index < sortedBreakpoints.length - 1; index++) {
      final start = sortedBreakpoints[index];
      final end = sortedBreakpoints[index + 1];
      if (end <= start) continue;
      final activeMarks = normalizedMarks.where(
        (mark) => mark.start < end && mark.end > start,
      );
      children.add(
        TextSpan(
          text: text.substring(start, end),
          style: _styleFor(baseStyle, activeMarks, hasComposing, start, end),
        ),
      );
    }
    return TextSpan(style: baseStyle, children: children);
  }

  List<StoryInlineMark> _normalizedMarks(int textLength) {
    if (textLength <= 0) return const [];
    return _block.marks
        .where((mark) => mark.start >= 0 && mark.end > mark.start)
        .map(
          (mark) => mark.copyWith(
            start: _clampOffset(mark.start, textLength),
            end: _clampOffset(mark.end, textLength),
          ),
        )
        .where((mark) => mark.end > mark.start)
        .toList(growable: false);
  }

  TextStyle _styleFor(
    TextStyle base,
    Iterable<StoryInlineMark> marks,
    bool hasComposing,
    int start,
    int end,
  ) {
    var next = base;
    final decorations = <TextDecoration>[];

    void addDecoration(TextDecoration decoration) {
      if (!decorations.contains(decoration)) {
        decorations.add(decoration);
      }
    }

    for (final mark in marks) {
      next = switch (mark.type) {
        StoryInlineMarkType.bold => next.copyWith(fontWeight: FontWeight.w800),
        StoryInlineMarkType.italic => next.copyWith(
          fontStyle: FontStyle.italic,
        ),
        StoryInlineMarkType.underline => next,
        StoryInlineMarkType.strikethrough => next,
        StoryInlineMarkType.link => next.copyWith(color: AppColors.accent),
      };
      switch (mark.type) {
        case StoryInlineMarkType.underline:
          addDecoration(TextDecoration.underline);
        case StoryInlineMarkType.strikethrough:
          addDecoration(TextDecoration.lineThrough);
        case StoryInlineMarkType.link:
          addDecoration(TextDecoration.underline);
        case StoryInlineMarkType.bold:
        case StoryInlineMarkType.italic:
          break;
      }
    }
    final composing = value.composing;
    if (hasComposing && composing.start < end && composing.end > start) {
      addDecoration(TextDecoration.underline);
    }
    if (decorations.isNotEmpty) {
      next = next.copyWith(
        decoration: TextDecoration.combine(decorations),
        decorationColor: decorations.contains(TextDecoration.underline)
            ? AppColors.accent
            : next.decorationColor,
      );
    }
    return next;
  }

  int _clampOffset(int value, int max) => value.clamp(0, max).toInt();
}
