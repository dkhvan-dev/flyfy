import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../../../core/network/file_api.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../domain/story_document.dart';
import '../story_editor_controller.dart';
import 'story_editor_style.dart';

class StoryMediaBlock extends StatelessWidget {
  const StoryMediaBlock({
    super.key,
    required this.block,
    this.queueItem,
    this.queueItems = const [],
    required this.selected,
    required this.onFocus,
    required this.onRetry,
    required this.onRemove,
    required this.onDelete,
    this.onRemoveGalleryImage,
  });

  final StoryBlock block;
  final StoryEditorMediaQueueItem? queueItem;
  final List<StoryEditorMediaQueueItem> queueItems;
  final bool selected;
  final VoidCallback onFocus;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final VoidCallback onDelete;
  final ValueChanged<int>? onRemoveGalleryImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final mediaItems = _normalizedQueueItems;
    final status = _effectiveStatus(block, mediaItems);
    final isFailed =
        status == StoryEditorMediaStatus.failed ||
        block.image?.uploadState == StoryUploadState.failed ||
        (block.gallery?.images.any(
              (image) => image.uploadState == StoryUploadState.failed,
            ) ??
            false);
    final canRetry = mediaItems.any(
      (item) => item.status == StoryEditorMediaStatus.failed,
    );
    final title = block.type == StoryBlockType.gallery
        ? l10n.storyEditorBlockGallery
        : l10n.storyEditorBlockImage;
    final mediaErrorLabel = _mediaErrorLabel(l10n, _firstFailedItem);
    StoryImagePayload? image;
    if (block.type == StoryBlockType.gallery) {
      final images = block.gallery?.images ?? const <StoryImagePayload>[];
      image = images.isEmpty ? null : images.first;
    } else {
      image = block.image;
    }

    return InkWell(
      borderRadius: AppBorderRadius.circular(8),
      onTap: onFocus,
      child: DecoratedBox(
        decoration: storyEditorPanelDecoration(context).copyWith(
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(StoryEditorSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    block.type == StoryBlockType.gallery
                        ? Icons.photo_library_outlined
                        : Icons.image_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: StoryEditorSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.storyEditorDeleteBlockSemantic(
                      title.toLowerCase(),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: StoryEditorSpacing.md),
              if (block.type == StoryBlockType.gallery)
                _GalleryPreviewCarousel(
                  images: block.gallery?.images ?? const <StoryImagePayload>[],
                  queueItems: mediaItems,
                  onRemoveImage: onRemoveGalleryImage,
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _MediaPreviewFrame(
                          child: _MediaPreview(
                            key: ValueKey(
                              'story-editor-media-preview-${queueItem?.localMediaId ?? block.id}',
                            ),
                            image: image,
                            queueItem: queueItem,
                            fallbackIcon: _fallbackIconForStatus(
                              status,
                              block.image?.uploadState,
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: StoryEditorSpacing.xs,
                        end: StoryEditorSpacing.xs,
                        child: _MediaPreviewStatusPill(
                          key: ValueKey(
                            'story-editor-image-status-${queueItem?.localMediaId ?? block.id}',
                          ),
                          status: status,
                          uploadState: block.image?.uploadState,
                        ),
                      ),
                    ],
                  ),
                ),
              if (canRetry) ...[
                const SizedBox(height: StoryEditorSpacing.md),
                Wrap(
                  spacing: StoryEditorSpacing.sm,
                  runSpacing: StoryEditorSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      label: l10n.storyEditorMediaRetrySemantic,
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.storyEditorMediaRetry),
                      ),
                    ),
                  ],
                ),
              ],
              if (isFailed && mediaErrorLabel != null) ...[
                const SizedBox(height: StoryEditorSpacing.sm),
                Text(
                  mediaErrorLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              if (_hasUnavailableLocalPreview(mediaItems) &&
                  mediaErrorLabel == null &&
                  (status == StoryEditorMediaStatus.failed ||
                      status == StoryEditorMediaStatus.queued ||
                      status == StoryEditorMediaStatus.uploading)) ...[
                const SizedBox(height: StoryEditorSpacing.sm),
                Text(
                  l10n.storyEditorMediaLocalPreviewUnavailable,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<StoryEditorMediaQueueItem> get _normalizedQueueItems {
    final all = queueItems.isEmpty ? [?queueItem] : queueItems;
    return all
        .where((item) => item.status != StoryEditorMediaStatus.removed)
        .toList(growable: false)
      ..sort((left, right) {
        final leftIndex = left.galleryImageIndex;
        final rightIndex = right.galleryImageIndex;
        if (leftIndex != null && rightIndex != null) {
          return leftIndex.compareTo(rightIndex);
        }
        if (leftIndex != null) return -1;
        if (rightIndex != null) return 1;
        return left.localMediaId.compareTo(right.localMediaId);
      });
  }

  StoryEditorMediaQueueItem? get _firstFailedItem {
    for (final item in _normalizedQueueItems) {
      if (item.status == StoryEditorMediaStatus.failed) {
        return item;
      }
    }
    return null;
  }

  String? _mediaErrorLabel(
    AppLocalizations l10n,
    StoryEditorMediaQueueItem? item,
  ) {
    if (item == null) return null;
    final code = item.errorCode;
    if (code == null && (item.errorMessage ?? '').trim().isNotEmpty) {
      return l10n.storyEditorMediaErrorUploadFailed;
    }
    if (code == null) return null;
    return switch (code) {
      StoryEditorMediaErrorCode.retryUpload =>
        l10n.storyEditorMediaErrorRetryUpload,
      StoryEditorMediaErrorCode.uploadInterrupted =>
        l10n.storyEditorMediaErrorInterrupted,
      StoryEditorMediaErrorCode.missingSource =>
        l10n.storyEditorMediaErrorMissingSource,
      StoryEditorMediaErrorCode.uploadFailed =>
        l10n.storyEditorMediaErrorUploadFailed,
    };
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    super.key,
    required this.queueItem,
    required this.fallbackIcon,
    this.image,
  });

  final StoryEditorMediaQueueItem? queueItem;
  final IconData fallbackIcon;
  final StoryImagePayload? image;

  @override
  Widget build(BuildContext context) {
    final bytes = queueItem?.previewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppBorderRadius.circular(8),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return Icon(fallbackIcon, size: 36);
          },
        ),
      );
    }

    final localPath = queueItem?.localPath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppBorderRadius.circular(8),
        child: Image.file(
          io.File(localPath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Icon(fallbackIcon, size: 36);
          },
        ),
      );
    }

    final imageUrl = resolvePublicFileContentUrl(image?.fileId ?? '');
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: AppBorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Icon(fallbackIcon, size: 36);
          },
        ),
      );
    }

    return Icon(fallbackIcon, size: 36);
  }
}

class _GalleryPreviewCarousel extends StatelessWidget {
  const _GalleryPreviewCarousel({
    required this.images,
    required this.queueItems,
    required this.onRemoveImage,
  });

  final List<StoryImagePayload> images;
  final List<StoryEditorMediaQueueItem> queueItems;
  final ValueChanged<int>? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final itemCount = math.max(images.length, queueItems.length);
    if (itemCount == 0) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _MediaPreviewFrame(
          child: Icon(Icons.photo_library_outlined, color: colors.textMuted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = StoryEditorSpacing.sm;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final normalizedWidth = math.max(1.0, availableWidth);
        final itemWidth = math.max(
          144.0,
          math.min(normalizedWidth * 0.74, 280.0),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < itemCount; index++)
                Padding(
                  padding: AppEdgeInsetsDirectional.only(
                    end: index == itemCount - 1 ? 0 : gap,
                  ),
                  child: SizedBox(
                    width: itemWidth,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _GalleryPreviewTile(
                        image: index < images.length ? images[index] : null,
                        queueItem: _queueItemForImage(index),
                        index: index,
                        onRemove: onRemoveImage == null
                            ? null
                            : () => onRemoveImage!(index),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  StoryEditorMediaQueueItem? _queueItemForImage(int imageIndex) {
    for (final item in queueItems) {
      if (item.galleryImageIndex == imageIndex) {
        return item;
      }
    }
    if (queueItems.any((item) => item.galleryImageIndex != null)) {
      return null;
    }
    return imageIndex < queueItems.length ? queueItems[imageIndex] : null;
  }
}

class _GalleryPreviewTile extends StatelessWidget {
  const _GalleryPreviewTile({
    required this.image,
    required this.queueItem,
    required this.index,
    this.onRemove,
  });

  final StoryImagePayload? image;
  final StoryEditorMediaQueueItem? queueItem;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final uploadState = image?.uploadState;
    final status = queueItem?.status;
    final previewKey = queueItem?.localMediaId ?? image?.fileId ?? '$index';

    return Stack(
      children: [
        Positioned.fill(
          child: _MediaPreviewFrame(
            child: _MediaPreview(
              key: ValueKey('story-editor-media-preview-$previewKey'),
              image: image,
              queueItem: queueItem,
              fallbackIcon: _fallbackIconForStatus(status, uploadState),
            ),
          ),
        ),
        if (onRemove != null)
          PositionedDirectional(
            top: StoryEditorSpacing.xs,
            start: StoryEditorSpacing.xs,
            child: Tooltip(
              message: l10n.storyEditorMediaRemove,
              child: IconButton(
                key: ValueKey('story-editor-gallery-remove-$previewKey'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface.withValues(alpha: 0.86),
                  foregroundColor: colors.danger,
                  side: BorderSide(
                    color: colors.danger.withValues(alpha: 0.45),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onRemove,
              ),
            ),
          ),
        PositionedDirectional(
          top: StoryEditorSpacing.xs,
          end: StoryEditorSpacing.xs,
          child: _MediaPreviewStatusPill(
            key: ValueKey('story-editor-gallery-status-$previewKey'),
            status: status,
            uploadState: uploadState,
          ),
        ),
      ],
    );
  }
}

class _MediaPreviewStatusPill extends StatelessWidget {
  const _MediaPreviewStatusPill({
    super.key,
    required this.status,
    this.uploadState,
  });

  final StoryEditorMediaStatus? status;
  final StoryUploadState? uploadState;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final effectiveStatus = status;
    final failed =
        effectiveStatus == StoryEditorMediaStatus.failed ||
        uploadState == StoryUploadState.failed;
    final done =
        effectiveStatus == StoryEditorMediaStatus.uploaded ||
        uploadState == StoryUploadState.complete;
    final icon = failed
        ? Icons.error_outline_rounded
        : done
        ? Icons.check_rounded
        : Icons.schedule_rounded;
    final color = failed
        ? colors.danger
        : done
        ? colors.success
        : colors.primary;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surface.withValues(alpha: 0.82),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(StoryEditorSpacing.xs),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _MediaPreviewFrame extends StatelessWidget {
  const _MediaPreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Center(child: child),
    );
  }
}

StoryEditorMediaStatus? _effectiveStatus(
  StoryBlock block,
  List<StoryEditorMediaQueueItem> queueItems,
) {
  if (queueItems.any((item) => item.status == StoryEditorMediaStatus.failed)) {
    return StoryEditorMediaStatus.failed;
  }
  if (queueItems.any(
    (item) => item.status == StoryEditorMediaStatus.uploading,
  )) {
    return StoryEditorMediaStatus.uploading;
  }
  if (queueItems.any((item) => item.status == StoryEditorMediaStatus.queued)) {
    return StoryEditorMediaStatus.queued;
  }
  if (queueItems.any(
    (item) => item.status == StoryEditorMediaStatus.uploaded,
  )) {
    return StoryEditorMediaStatus.uploaded;
  }
  if (queueItems.any((item) => item.status == StoryEditorMediaStatus.removed)) {
    return StoryEditorMediaStatus.removed;
  }
  if (block.image?.isUploadComplete ?? false) {
    return StoryEditorMediaStatus.uploaded;
  }
  final galleryImages = block.gallery?.images ?? const <StoryImagePayload>[];
  if (galleryImages.isNotEmpty &&
      galleryImages.every((image) => image.isUploadComplete)) {
    return StoryEditorMediaStatus.uploaded;
  }
  if (block.image?.uploadState == StoryUploadState.failed ||
      galleryImages.any(
        (image) => image.uploadState == StoryUploadState.failed,
      )) {
    return StoryEditorMediaStatus.failed;
  }
  if (block.image?.uploadState == StoryUploadState.uploading ||
      galleryImages.any(
        (image) => image.uploadState == StoryUploadState.uploading,
      )) {
    return StoryEditorMediaStatus.uploading;
  }
  return null;
}

IconData _fallbackIconForStatus(
  StoryEditorMediaStatus? status,
  StoryUploadState? uploadState,
) {
  final failed =
      status == StoryEditorMediaStatus.failed ||
      uploadState == StoryUploadState.failed;
  if (failed) {
    return Icons.error_outline_rounded;
  }
  final done =
      status == StoryEditorMediaStatus.uploaded ||
      uploadState == StoryUploadState.complete;
  if (done) {
    return Icons.check_circle_outline_rounded;
  }
  return Icons.cloud_upload_outlined;
}

bool _hasUnavailableLocalPreview(List<StoryEditorMediaQueueItem> queueItems) {
  return queueItems.any((item) {
    final needsLocalPreview =
        item.status == StoryEditorMediaStatus.failed ||
        item.status == StoryEditorMediaStatus.queued ||
        item.status == StoryEditorMediaStatus.uploading;
    return needsLocalPreview && !item.hasUploadSource;
  });
}
