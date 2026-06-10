import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/ui/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../story_ui.dart';
import '../../domain/story_document.dart';
import '../story_editor_controller.dart';
import 'story_editor_focus_visibility.dart';
import 'story_editor_style.dart';
import 'story_media_block.dart';
import 'story_text_block.dart';

class StoryBlockCanvas extends StatelessWidget {
  const StoryBlockCanvas({
    super.key,
    required this.state,
    required this.onSelectBlock,
    required this.onUpdateTextBlock,
    required this.onUpdateTextSelection,
    required this.onDeleteBlock,
    required this.onRetryMedia,
    required this.onRemoveMedia,
    required this.onRemoveGalleryImage,
    required this.onAddBlock,
    required this.onReorderBlock,
    this.scrollController,
    this.onTextInputFocused,
  });

  final StoryEditorState state;
  final ValueChanged<String?> onSelectBlock;
  final void Function(String blockId, String text) onUpdateTextBlock;
  final void Function(String blockId, TextSelection selection)
  onUpdateTextSelection;
  final ValueChanged<String> onDeleteBlock;
  final ValueChanged<String> onRetryMedia;
  final ValueChanged<String> onRemoveMedia;
  final void Function(String blockId, int imageIndex) onRemoveGalleryImage;
  final VoidCallback onAddBlock;
  final void Function(String blockId, int newIndex) onReorderBlock;
  final ScrollController? scrollController;
  final ValueChanged<BuildContext>? onTextInputFocused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocks = state.document.blocks;
    final contentError = _contentErrorText(l10n);
    if (blocks.isEmpty) {
      return DecoratedBox(
        decoration: _contentPanelDecoration(context, contentError != null),
        child: Padding(
          padding: const EdgeInsets.all(StoryEditorSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 40,
                color: AppColors.accent,
              ),
              const SizedBox(height: StoryEditorSpacing.md),
              Text(
                l10n.storyEditorStartWithBlockTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: StoryEditorSpacing.sm),
              Text(
                l10n.storyEditorStartWithBlockSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (contentError != null) ...[
                const SizedBox(height: StoryEditorSpacing.sm),
                Text(
                  contentError,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.destructive),
                ),
              ],
              const SizedBox(height: StoryEditorSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: FilledButton(
                      onPressed: onAddBlock,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded),
                          const SizedBox(width: StoryEditorSpacing.sm),
                          Flexible(
                            child: Text(
                              l10n.storyEditorToolbarAddBlock,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return _ReorderableBlockList(
      state: state,
      scrollController: scrollController,
      onSelectBlock: onSelectBlock,
      onUpdateTextBlock: onUpdateTextBlock,
      onUpdateTextSelection: onUpdateTextSelection,
      onDeleteBlock: onDeleteBlock,
      onRetryMedia: onRetryMedia,
      onRemoveMedia: onRemoveMedia,
      onRemoveGalleryImage: onRemoveGalleryImage,
      onReorderBlock: onReorderBlock,
      onTextInputFocused: onTextInputFocused,
    );
  }

  String? _contentErrorText(AppLocalizations l10n) {
    final shouldShow =
        state.saveStatus.phase == StoryEditorSavePhase.failed ||
        state.saveStatus.phase == StoryEditorSavePhase.conflict;
    if (!shouldShow) {
      return null;
    }
    for (final error in state.publishValidation.errors) {
      if (error.field != 'contentBlocks') {
        continue;
      }
      return switch (error.code.trim()) {
        'draft_required' => l10n.storyEditorValidationDraftRequired,
        'content_required' => l10n.storyEditorValidationContentRequired,
        _ => error.message,
      };
    }
    return null;
  }

  BoxDecoration _contentPanelDecoration(BuildContext context, bool hasError) {
    if (!hasError) {
      return storyEditorPanelDecoration(context);
    }
    return BoxDecoration(
      color: AppColors.surfaceLight,
      border: Border.all(color: AppColors.destructive, width: 1.4),
      borderRadius: BorderRadius.circular(8),
    );
  }
}

class _ReorderableBlockList extends StatefulWidget {
  const _ReorderableBlockList({
    required this.state,
    required this.scrollController,
    required this.onSelectBlock,
    required this.onUpdateTextBlock,
    required this.onUpdateTextSelection,
    required this.onDeleteBlock,
    required this.onRetryMedia,
    required this.onRemoveMedia,
    required this.onRemoveGalleryImage,
    required this.onReorderBlock,
    this.onTextInputFocused,
  });

  final StoryEditorState state;
  final ScrollController? scrollController;
  final ValueChanged<String?> onSelectBlock;
  final void Function(String blockId, String text) onUpdateTextBlock;
  final void Function(String blockId, TextSelection selection)
  onUpdateTextSelection;
  final ValueChanged<String> onDeleteBlock;
  final ValueChanged<String> onRetryMedia;
  final ValueChanged<String> onRemoveMedia;
  final void Function(String blockId, int imageIndex) onRemoveGalleryImage;
  final void Function(String blockId, int newIndex) onReorderBlock;
  final ValueChanged<BuildContext>? onTextInputFocused;

  @override
  State<_ReorderableBlockList> createState() => _ReorderableBlockListState();
}

class _ReorderableBlockListState extends State<_ReorderableBlockList> {
  static const _autoScrollTick = Duration(milliseconds: 16);
  static const _autoScrollEdgeExtent = 88.0;
  static const _autoScrollMaxStep = 18.0;

  Timer? _autoScrollTimer;
  Offset? _lastDragGlobalPosition;
  bool _reordering = false;

  @override
  void dispose() {
    _stopAutoScroll(clearPosition: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.state.document.blocks;
    final l10n = AppLocalizations.of(context)!;
    return Listener(
      onPointerMove: _handlePointerMove,
      onPointerUp: (_) => _stopDrag(),
      onPointerCancel: (_) => _stopDrag(),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderStart: _handleReorderStart,
        onReorderEnd: (_) => _stopDrag(),
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                color: Colors.transparent,
                elevation: 8 * animation.value,
                borderRadius: BorderRadius.circular(8),
                child: child,
              );
            },
            child: child,
          );
        },
        itemCount: blocks.length,
        onReorderItem: (oldIndex, newIndex) {
          widget.onReorderBlock(blocks[oldIndex].id, newIndex);
        },
        itemBuilder: (context, index) {
          final block = blocks[index];
          final blockLabel = storyBlockTypeLabel(l10n, block.type);
          return Padding(
            key: ValueKey('story-editor-block-row-${block.id}'),
            padding: const EdgeInsets.only(bottom: StoryEditorSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReorderableDelayedDragStartListener(
                  index: index,
                  child: _BlockDragHandle(
                    blockId: block.id,
                    semanticLabel: l10n.storyEditorReorderBlockSemantic(
                      blockLabel.toLowerCase(),
                    ),
                  ),
                ),
                const SizedBox(width: StoryEditorSpacing.sm),
                Expanded(
                  child: _BlockRenderer(
                    block: block,
                    state: widget.state,
                    selected: widget.state.selectedBlockId == block.id,
                    onSelectBlock: widget.onSelectBlock,
                    onUpdateTextBlock: widget.onUpdateTextBlock,
                    onUpdateTextSelection: widget.onUpdateTextSelection,
                    onDeleteBlock: widget.onDeleteBlock,
                    onRetryMedia: widget.onRetryMedia,
                    onRemoveMedia: widget.onRemoveMedia,
                    onRemoveGalleryImage: widget.onRemoveGalleryImage,
                    onTextInputFocused: widget.onTextInputFocused,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleReorderStart(int index) {
    _reordering = true;
    unawaited(HapticFeedback.selectionClick());
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_reordering) {
      return;
    }
    _lastDragGlobalPosition = event.position;
    _updateAutoScroll();
  }

  void _stopDrag() {
    _reordering = false;
    _stopAutoScroll(clearPosition: true);
  }

  void _updateAutoScroll() {
    if (_autoScrollStep() == 0) {
      _stopAutoScroll(clearPosition: false);
      return;
    }
    _autoScrollTimer ??= Timer.periodic(_autoScrollTick, (_) {
      _tickAutoScroll();
    });
    _tickAutoScroll();
  }

  void _tickAutoScroll() {
    final controller = widget.scrollController;
    final step = _autoScrollStep();
    if (controller == null || step == 0) {
      _stopAutoScroll(clearPosition: false);
      return;
    }
    final position = controller.position;
    final target = (position.pixels + step)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 0.1) {
      _stopAutoScroll(clearPosition: false);
      return;
    }
    controller.jumpTo(target);
  }

  double _autoScrollStep() {
    final controller = widget.scrollController;
    final dragPosition = _lastDragGlobalPosition;
    if (!_reordering ||
        controller == null ||
        !controller.hasClients ||
        dragPosition == null) {
      return 0;
    }
    final viewport = _scrollViewportRect();
    if (viewport == null) {
      return 0;
    }
    final position = controller.position;
    final topDistance = dragPosition.dy - viewport.top;
    final bottomDistance = viewport.bottom - dragPosition.dy;
    if (topDistance < _autoScrollEdgeExtent &&
        position.pixels > position.minScrollExtent) {
      final intensity =
          (_autoScrollEdgeExtent -
              topDistance.clamp(0, _autoScrollEdgeExtent)) /
          _autoScrollEdgeExtent;
      return -_autoScrollMaxStep * intensity;
    }
    if (bottomDistance < _autoScrollEdgeExtent &&
        position.pixels < position.maxScrollExtent) {
      final intensity =
          (_autoScrollEdgeExtent -
              bottomDistance.clamp(0, _autoScrollEdgeExtent)) /
          _autoScrollEdgeExtent;
      return _autoScrollMaxStep * intensity;
    }
    return 0;
  }

  Rect? _scrollViewportRect() {
    final scrollableRenderObject = Scrollable.maybeOf(
      context,
    )?.context.findRenderObject();
    final renderObject = scrollableRenderObject ?? context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  void _stopAutoScroll({required bool clearPosition}) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (clearPosition) {
      _lastDragGlobalPosition = null;
    }
  }
}

class _BlockDragHandle extends StatelessWidget {
  const _BlockDragHandle({required this.blockId, required this.semanticLabel});

  final String blockId;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final handleWidth = adaptive.scale(36, minFactor: 0.86, maxFactor: 1.08);
    final handleHeight = adaptive.scale(48, minFactor: 0.86, maxFactor: 1.08);
    final barWidth = adaptive.scale(18, minFactor: 0.86, maxFactor: 1.08);
    final barHeight = adaptive.scale(2, minFactor: 0.86, maxFactor: 1.08);
    final barGap = adaptive.scale(4, minFactor: 0.86, maxFactor: 1.08);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: SizedBox(
        key: ValueKey('story-editor-block-drag-handle-$blockId'),
        width: handleWidth,
        height: handleHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: SizedBox(width: barWidth, height: barHeight),
                ),
                if (i < 2) SizedBox(height: barGap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockRenderer extends StatelessWidget {
  const _BlockRenderer({
    required this.block,
    required this.state,
    required this.selected,
    required this.onSelectBlock,
    required this.onUpdateTextBlock,
    required this.onUpdateTextSelection,
    required this.onDeleteBlock,
    required this.onRetryMedia,
    required this.onRemoveMedia,
    required this.onRemoveGalleryImage,
    this.onTextInputFocused,
  });

  final StoryBlock block;
  final StoryEditorState state;
  final bool selected;
  final ValueChanged<String?> onSelectBlock;
  final void Function(String blockId, String text) onUpdateTextBlock;
  final void Function(String blockId, TextSelection selection)
  onUpdateTextSelection;
  final ValueChanged<String> onDeleteBlock;
  final ValueChanged<String> onRetryMedia;
  final ValueChanged<String> onRemoveMedia;
  final void Function(String blockId, int imageIndex) onRemoveGalleryImage;
  final ValueChanged<BuildContext>? onTextInputFocused;

  @override
  Widget build(BuildContext context) {
    if (block.isTextBlock) {
      return StoryTextBlock(
        key: ValueKey(block.id),
        block: block,
        selected: selected,
        onFocus: () => onSelectBlock(block.id),
        onChanged: (text) => onUpdateTextBlock(block.id, text),
        onSelectionChanged: (selection) =>
            onUpdateTextSelection(block.id, selection),
        onDelete: () => onDeleteBlock(block.id),
        onTextInputFocused: onTextInputFocused,
      );
    }

    switch (block.type) {
      case StoryBlockType.image:
      case StoryBlockType.gallery:
        final queueItems = <StoryEditorMediaQueueItem>[];
        for (final item in state.mediaQueue.items) {
          if (item.blockId == block.id) {
            queueItems.add(item);
          }
        }
        final queueItem = _primaryMediaQueueItem(queueItems);
        return StoryMediaBlock(
          key: ValueKey(block.id),
          block: block,
          queueItem: queueItem,
          queueItems: queueItems,
          selected: selected,
          onFocus: () => onSelectBlock(block.id),
          onRetry: () {
            final localMediaId =
                _firstMediaQueueItemWithStatus(
                  queueItems,
                  StoryEditorMediaStatus.failed,
                )?.localMediaId ??
                queueItem?.localMediaId;
            if (localMediaId != null) onRetryMedia(localMediaId);
          },
          onRemove: () {
            final localMediaId = queueItem?.localMediaId;
            if (localMediaId != null) onRemoveMedia(localMediaId);
          },
          onDelete: () => onDeleteBlock(block.id),
          onRemoveGalleryImage: (imageIndex) =>
              onRemoveGalleryImage(block.id, imageIndex),
        );
      case StoryBlockType.divider:
        return _DividerBlock(
          selected: selected,
          onTap: () => onSelectBlock(block.id),
          onDelete: () => onDeleteBlock(block.id),
        );
      case StoryBlockType.placeReference:
        return _PlaceReferenceBlock(
          block: block,
          selected: selected,
          onTap: () => onSelectBlock(block.id),
          onChanged: (value) => onUpdateTextBlock(block.id, value),
          onDelete: () => onDeleteBlock(block.id),
          onTextInputFocused: onTextInputFocused,
        );
      case StoryBlockType.paragraph:
      case StoryBlockType.heading:
      case StoryBlockType.bulletedList:
      case StoryBlockType.numberedList:
      case StoryBlockType.quote:
      case StoryBlockType.callout:
        return const SizedBox.shrink();
    }
  }
}

StoryEditorMediaQueueItem? _primaryMediaQueueItem(
  List<StoryEditorMediaQueueItem> items,
) {
  return _firstMediaQueueItemWithStatus(items, StoryEditorMediaStatus.failed) ??
      _firstMediaQueueItemWithStatus(items, StoryEditorMediaStatus.uploading) ??
      _firstMediaQueueItemWithStatus(items, StoryEditorMediaStatus.queued) ??
      (items.isEmpty ? null : items.first);
}

StoryEditorMediaQueueItem? _firstMediaQueueItemWithStatus(
  List<StoryEditorMediaQueueItem> items,
  StoryEditorMediaStatus status,
) {
  for (final item in items) {
    if (item.status == status) {
      return item;
    }
  }
  return null;
}

class _DividerBlock extends StatelessWidget {
  const _DividerBlock({
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: storyEditorPanelDecoration(context).copyWith(
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StoryEditorSpacing.md),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              IconButton(
                tooltip: l10n.storyEditorDeleteBlockSemantic(
                  l10n.storyEditorBlockDivider.toLowerCase(),
                ),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceReferenceBlock extends StatefulWidget {
  const _PlaceReferenceBlock({
    required this.block,
    required this.selected,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
    this.onTextInputFocused,
  });

  final StoryBlock block;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  final ValueChanged<BuildContext>? onTextInputFocused;

  @override
  State<_PlaceReferenceBlock> createState() => _PlaceReferenceBlockState();
}

class _PlaceReferenceBlockState extends State<_PlaceReferenceBlock> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.place?.name ?? '');
  }

  @override
  void didUpdateWidget(covariant _PlaceReferenceBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.block.place?.name ?? '';
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: widget.onTap,
      child: DecoratedBox(
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
                  const Icon(Icons.place_outlined, size: 20),
                  const SizedBox(width: StoryEditorSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.storyEditorBlockPlaceReference,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.storyEditorDeleteBlockSemantic(
                      l10n.storyEditorBlockPlaceReference.toLowerCase(),
                    ),
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              StoryEditorRevealOnFocus(
                onFocus: widget.onTextInputFocused,
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: l10n.storyEditorPlaceNameHint,
                    border: InputBorder.none,
                  ),
                  onTap: widget.onTap,
                  onChanged: widget.onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
