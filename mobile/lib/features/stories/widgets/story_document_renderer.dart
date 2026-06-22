import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/network/file_api.dart';
import '../../../core/ui/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../editor/domain/story_document.dart';
import '../models/post_vm.dart';
import '../story_ui.dart';

typedef StoryImageOpenCallback =
    void Function(List<StoryImagePayload> images, int initialIndex);
typedef StoryRouteOpenCallback = void Function(String routeId);

class StoryDocumentRenderer extends StatelessWidget {
  const StoryDocumentRenderer({
    super.key,
    this.story,
    this.document,
    this.fallbackContent,
    this.onOpenImages,
    this.onOpenRoute,
  });

  final PostVm? story;
  final StoryDocument? document;
  final String? fallbackContent;
  final StoryImageOpenCallback? onOpenImages;
  final StoryRouteOpenCallback? onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final blocks = _resolveDocument().blocks
        .map(
          (block) => _StoryRenderedBlock(
            block: block,
            onOpenImages: onOpenImages,
            onOpenRoute: onOpenRoute,
          ),
        )
        .where((block) => block.visible)
        .toList(growable: false);

    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    final adaptive = StoryAdaptive.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          blocks[index],
          if (index != blocks.length - 1)
            SizedBox(height: adaptive.scale(_spacingAfter(blocks[index].type))),
        ],
      ],
    );
  }

  StoryDocument _resolveDocument() {
    final explicitDocument = document;
    if (explicitDocument != null) {
      return explicitDocument;
    }

    final currentStory = story;
    if (currentStory != null) {
      if (currentStory.contentBlocks.isNotEmpty) {
        return StoryDocument(
          version: currentStory.contentSchemaVersion,
          blocks: currentStory.contentBlocks
              .map(_blockFromJson)
              .whereType<StoryBlock>()
              .toList(growable: false),
        );
      }

      final excerpt = currentStory.excerpt.trim();
      if (excerpt.isNotEmpty) {
        return StoryDocument(
          blocks: [StoryBlock.paragraph(id: 'excerpt-0', text: excerpt)],
        );
      }
    }

    final fallback = (fallbackContent ?? '').trim();
    if (fallback.isNotEmpty) {
      return StoryDocument(
        blocks: [StoryBlock.paragraph(id: 'fallback-0', text: fallback)],
      );
    }
    return StoryDocument();
  }

  double _spacingAfter(StoryBlockType type) {
    return switch (type) {
      StoryBlockType.heading => 12,
      StoryBlockType.divider => 18,
      StoryBlockType.image || StoryBlockType.gallery => 18,
      _ => 16,
    };
  }
}

class _StoryRenderedBlock extends StatelessWidget {
  const _StoryRenderedBlock({
    required this.block,
    required this.onOpenImages,
    required this.onOpenRoute,
  });

  final StoryBlock block;
  final StoryImageOpenCallback? onOpenImages;
  final StoryRouteOpenCallback? onOpenRoute;

  StoryBlockType get type => block.type;

  bool get visible {
    return switch (block.type) {
      StoryBlockType.paragraph ||
      StoryBlockType.heading ||
      StoryBlockType.quote ||
      StoryBlockType.callout => (block.text ?? '').trim().isNotEmpty,
      StoryBlockType.bulletedList ||
      StoryBlockType.numberedList => _listItems(block.text).isNotEmpty,
      StoryBlockType.image => _validImage(block.image) != null,
      StoryBlockType.gallery => _validGalleryImages(block.gallery).isNotEmpty,
      StoryBlockType.placeReference =>
        (block.place?.isMeaningful ?? false) && _placeTitle(block).isNotEmpty,
      StoryBlockType.routeReference =>
        (block.route?.isMeaningful ?? false) && _routeTitle(block).isNotEmpty,
      StoryBlockType.divider => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return switch (block.type) {
      StoryBlockType.heading => _HeadingBlock(block: block),
      StoryBlockType.paragraph => _ParagraphBlock(block: block),
      StoryBlockType.bulletedList => _ListBlock(block: block, ordered: false),
      StoryBlockType.numberedList => _ListBlock(block: block, ordered: true),
      StoryBlockType.quote => _QuoteBlock(block: block),
      StoryBlockType.callout => _CalloutBlock(block: block),
      StoryBlockType.image => _ImageBlock(
        image: block.image!,
        onOpenImages: onOpenImages,
      ),
      StoryBlockType.gallery => _GalleryBlock(
        gallery: block.gallery!,
        onOpenImages: onOpenImages,
      ),
      StoryBlockType.divider => const _DividerBlock(),
      StoryBlockType.placeReference => _PlaceReferenceBlock(block: block),
      StoryBlockType.routeReference => _RouteReferenceBlock(
        block: block,
        onOpenRoute: onOpenRoute,
      ),
    };
  }
}

class _HeadingBlock extends StatelessWidget {
  const _HeadingBlock({required this.block});

  final StoryBlock block;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final level = (block.level ?? 1).clamp(1, 3);
    final size = switch (level) {
      1 => 24.0,
      2 => 20.0,
      _ => 18.0,
    };
    return _MarkedText(
      text: block.text ?? '',
      marks: block.marks,
      style: TextStyle(
        color: StoryPalette.text,
        fontSize: adaptive.scale(size),
        height: 1.18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ParagraphBlock extends StatelessWidget {
  const _ParagraphBlock({required this.block});

  final StoryBlock block;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return _MarkedText(
      text: block.text ?? '',
      marks: block.marks,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.84),
        fontSize: adaptive.scale(15),
        height: 1.8,
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.block, required this.ordered});

  final StoryBlock block;
  final bool ordered;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final items = _listItems(block.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : adaptive.scale(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: adaptive.scale(22),
                  child: ordered
                      ? Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: adaptive.scale(13),
                            fontWeight: FontWeight.w800,
                            height: 1.65,
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.only(top: adaptive.scale(9)),
                          child: Icon(
                            Icons.circle,
                            size: adaptive.scale(6),
                            color: AppColors.accent,
                          ),
                        ),
                ),
                Expanded(
                  child: _MarkedText(
                    text: items[index],
                    marks: const [],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: adaptive.scale(15),
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.block});

  final StoryBlock block;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.75),
            width: adaptive.scale(3),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: adaptive.scale(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: AppColors.accent.withValues(alpha: 0.7),
              size: adaptive.scale(24),
            ),
            SizedBox(width: adaptive.scale(8)),
            Expanded(
              child: _MarkedText(
                text: block.text ?? '',
                marks: block.marks,
                style: TextStyle(
                  color: StoryPalette.textSoft,
                  fontSize: adaptive.scale(17),
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalloutBlock extends StatelessWidget {
  const _CalloutBlock({required this.block});

  final StoryBlock block;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(adaptive.scale(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(18)),
        color: AppColors.accent.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.accent,
            size: adaptive.scale(20),
          ),
          SizedBox(width: adaptive.scale(10)),
          Expanded(
            child: _MarkedText(
              text: block.text ?? '',
              marks: block.marks,
              style: TextStyle(
                color: StoryPalette.text,
                fontSize: adaptive.scale(14),
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.image, required this.onOpenImages});

  final StoryImagePayload image;
  final StoryImageOpenCallback? onOpenImages;

  @override
  Widget build(BuildContext context) {
    final validImage = _validImage(image)!;
    return _ResponsiveImage(
      key: ValueKey('story-document-image-${validImage.fileId}-0'),
      fileId: validImage.fileId,
      onTap: onOpenImages == null
          ? null
          : () => onOpenImages!(List.unmodifiable([validImage]), 0),
    );
  }
}

class _GalleryBlock extends StatelessWidget {
  const _GalleryBlock({required this.gallery, required this.onOpenImages});

  final StoryGalleryPayload gallery;
  final StoryImageOpenCallback? onOpenImages;

  @override
  Widget build(BuildContext context) {
    final images = _validGalleryImages(gallery);
    return LayoutBuilder(
      builder: (context, constraints) {
        final adaptive = StoryAdaptive.of(context);
        final gap = adaptive.scale(8);
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final itemWidth = math.max(
          adaptive.scale(144),
          math.min(math.max(1.0, availableWidth) * 0.74, adaptive.scale(280)),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < images.length; index++)
                Container(
                  width: itemWidth,
                  margin: EdgeInsetsDirectional.only(
                    end: index == images.length - 1 ? 0 : gap,
                  ),
                  child: _ResponsiveImage(
                    key: ValueKey(
                      'story-document-image-${images[index].fileId}-$index',
                    ),
                    fileId: images[index].fileId,
                    aspectRatio: 1,
                    radius: 16,
                    onTap: onOpenImages == null
                        ? null
                        : () => onOpenImages!(List.unmodifiable(images), index),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ResponsiveImage extends StatelessWidget {
  const _ResponsiveImage({
    super.key,
    required this.fileId,
    this.aspectRatio = 16 / 10,
    this.radius = 22,
    this.onTap,
  });

  final String fileId;
  final double aspectRatio;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final imageUrl = resolvePublicFileContentUrl(fileId);
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(adaptive.radius(radius)),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF2A1708)),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return const _RenderedImageLoadingPlaceholder();
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 30,
                ),
              );
            },
          ),
        ),
      ),
    );

    final tapHandler = onTap;
    if (tapHandler == null) {
      return image;
    }

    return Semantics(
      button: true,
      image: true,
      child: GestureDetector(
        onTap: tapHandler,
        behavior: HitTestBehavior.opaque,
        child: image,
      ),
    );
  }
}

class _RenderedImageLoadingPlaceholder extends StatelessWidget {
  const _RenderedImageLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Center(
      child: SizedBox.square(
        dimension: adaptive.scale(26),
        child: CircularProgressIndicator(
          strokeWidth: adaptive.scale(2),
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _DividerBlock extends StatelessWidget {
  const _DividerBlock();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: StoryAdaptive.of(context).scale(28),
      color: StoryPalette.line,
      thickness: 1,
    );
  }
}

class _PlaceReferenceBlock extends StatelessWidget {
  const _PlaceReferenceBlock({required this.block});

  final StoryBlock block;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final place = block.place!;
    final title = _placeTitle(block);
    final details = [
      (place.cityId ?? '').trim(),
      (place.countryCode ?? '').trim().toUpperCase(),
    ].where((item) => item.isNotEmpty).join(' / ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(adaptive.scale(13)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(18)),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.place_outlined,
            color: AppColors.accent,
            size: adaptive.scale(20),
          ),
          SizedBox(width: adaptive.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: StoryPalette.text,
                    fontSize: adaptive.scale(14),
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  SizedBox(height: adaptive.scale(3)),
                  Text(
                    details,
                    style: TextStyle(
                      color: StoryPalette.textMuted,
                      fontSize: adaptive.scale(11),
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteReferenceBlock extends StatelessWidget {
  const _RouteReferenceBlock({required this.block, required this.onOpenRoute});

  final StoryBlock block;
  final StoryRouteOpenCallback? onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context);
    final route = block.route!;
    final title = _routeTitle(block);
    final description = (route.description ?? '').trim();
    final routeId = route.routeId.trim();
    final metrics = <_RouteReferenceMetric>[
      if ((route.durationSeconds ?? 0) > 0)
        _RouteReferenceMetric(
          icon: Icons.schedule_rounded,
          value: _formatRouteDuration(route.durationSeconds!, l10n),
        ),
      if ((route.distanceMeters ?? 0) > 0)
        _RouteReferenceMetric(
          icon: Icons.straighten_rounded,
          value: _formatRouteDistance(route.distanceMeters!, l10n),
        ),
      if ((route.stopsCount ?? 0) > 0)
        _RouteReferenceMetric(
          icon: Icons.pin_drop_outlined,
          value:
              l10n?.userRoutesStopsCount(route.stopsCount!) ??
              '${route.stopsCount} stops',
        ),
    ];

    final content = Container(
      key: ValueKey('story-document-route-$routeId'),
      width: double.infinity,
      padding: EdgeInsets.all(adaptive.scale(13)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(18)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2108), Color(0xFF241406)],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: adaptive.scale(18),
            offset: Offset(0, adaptive.scale(8)),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: adaptive.scale(42),
            height: adaptive.scale(42),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(adaptive.radius(12)),
              color: AppColors.accent.withValues(alpha: 0.16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(
              Icons.route_rounded,
              color: AppColors.accent,
              size: adaptive.scale(22),
            ),
          ),
          SizedBox(width: adaptive.scale(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: StoryPalette.text,
                    fontSize: adaptive.scale(14.5),
                    height: 1.24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: adaptive.scale(4)),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: StoryPalette.textSoft.withValues(alpha: 0.84),
                      fontSize: adaptive.scale(12),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
                if (metrics.isNotEmpty) ...[
                  SizedBox(height: adaptive.scale(10)),
                  Wrap(
                    spacing: adaptive.scale(8),
                    runSpacing: adaptive.scale(8),
                    children: [
                      for (final metric in metrics)
                        _RouteReferenceMetricChip(metric: metric),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final openRoute = onOpenRoute;
    if (openRoute == null || routeId.isEmpty) {
      return content;
    }

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(adaptive.radius(18)),
          onTap: () => openRoute(routeId),
          child: content,
        ),
      ),
    );
  }
}

class _RouteReferenceMetric {
  const _RouteReferenceMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;
}

class _RouteReferenceMetricChip extends StatelessWidget {
  const _RouteReferenceMetricChip({required this.metric});

  final _RouteReferenceMetric metric;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(adaptive.radius(999)),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: adaptive.scale(9),
          vertical: adaptive.scale(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              metric.icon,
              color: AppColors.accent,
              size: adaptive.scale(14),
            ),
            SizedBox(width: adaptive.scale(5)),
            Text(
              metric.value,
              style: TextStyle(
                color: const Color(0xFFFFE6B4),
                fontSize: adaptive.scale(11),
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkedText extends StatelessWidget {
  const _MarkedText({
    required this.text,
    required this.marks,
    required this.style,
  });

  final String text;
  final List<StoryInlineMark> marks;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    if (marks.isEmpty || trimmed.length != text.length) {
      return Text(trimmed, style: style);
    }

    final normalizedMarks = marks
        .where((mark) => mark.start >= 0 && mark.end > mark.start)
        .map(
          (mark) => mark.copyWith(
            start: mark.start.clamp(0, text.length),
            end: mark.end.clamp(0, text.length),
          ),
        )
        .where((mark) => mark.end > mark.start)
        .toList(growable: false);
    if (normalizedMarks.isEmpty) {
      return Text(trimmed, style: style);
    }

    final breakpoints = <int>{0, text.length};
    for (final mark in normalizedMarks) {
      breakpoints
        ..add(mark.start)
        ..add(mark.end);
    }
    final sortedBreakpoints = breakpoints.toList(growable: false)..sort();
    final spans = <TextSpan>[];
    for (var index = 0; index < sortedBreakpoints.length - 1; index++) {
      final start = sortedBreakpoints[index];
      final end = sortedBreakpoints[index + 1];
      if (end <= start) continue;
      final activeMarks = normalizedMarks.where(
        (mark) => mark.start < end && mark.end > start,
      );
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: _styleForMarks(style, activeMarks),
        ),
      );
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }

  TextStyle _styleForMarks(TextStyle base, Iterable<StoryInlineMark> marks) {
    var next = base;
    final decorations = <TextDecoration>[];

    void addDecoration(TextDecoration decoration) {
      if (!decorations.contains(decoration)) {
        decorations.add(decoration);
      }
    }

    for (final mark in marks) {
      switch (mark.type) {
        case StoryInlineMarkType.bold:
          next = next.copyWith(fontWeight: FontWeight.w800);
        case StoryInlineMarkType.italic:
          next = next.copyWith(fontStyle: FontStyle.italic);
        case StoryInlineMarkType.underline:
          addDecoration(TextDecoration.underline);
        case StoryInlineMarkType.strikethrough:
          addDecoration(TextDecoration.lineThrough);
        case StoryInlineMarkType.link:
          next = next.copyWith(color: AppColors.accent);
          addDecoration(TextDecoration.underline);
      }
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
}

StoryBlock? _blockFromJson(Map<String, dynamic> json) {
  final id = (json['id']?.toString() ?? '').trim();
  final normalizedId = id.isEmpty ? 'story-block-${json.hashCode}' : id;
  final text = json['text']?.toString() ?? '';
  final marks = _marksFromJson(json['marks']);
  return switch (_normalizeBlockType(json['type'])) {
    'heading' => StoryBlock.heading(
      id: normalizedId,
      text: text,
      level: int.tryParse(json['level']?.toString() ?? '') ?? 1,
      marks: marks,
    ),
    'bulleted_list' => StoryBlock.bulletedList(
      id: normalizedId,
      text: _listTextFromJson(json, fallback: text),
      marks: marks,
    ),
    'numbered_list' => StoryBlock.numberedList(
      id: normalizedId,
      text: _listTextFromJson(json, fallback: text),
      marks: marks,
    ),
    'quote' => StoryBlock.quote(id: normalizedId, text: text, marks: marks),
    'callout' => StoryBlock.callout(id: normalizedId, text: text, marks: marks),
    'image' => StoryBlock.image(
      id: normalizedId,
      image: _imageFromJson(json['image'] ?? json),
    ),
    'gallery' => StoryBlock.gallery(
      id: normalizedId,
      gallery: StoryGalleryPayload(
        images: _galleryImagesFromJson(json['gallery'] ?? json),
      ),
    ),
    'divider' => StoryBlock.divider(id: normalizedId),
    'place_reference' => StoryBlock.placeReference(
      id: normalizedId,
      place: _placeFromJson(json['place'] ?? json),
    ),
    'route_reference' => StoryBlock.routeReference(
      id: normalizedId,
      route: _routeFromJson(json['route'] ?? json),
    ),
    'paragraph' ||
    _ => StoryBlock.paragraph(id: normalizedId, text: text, marks: marks),
  };
}

String _listTextFromJson(
  Map<String, dynamic> json, {
  required String fallback,
}) {
  final items = json['items'];
  if (items is! List) {
    return fallback;
  }
  return items
      .whereType<Map>()
      .map((item) => item['text']?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .join('\n');
}

List<StoryInlineMark> _marksFromJson(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map((mark) {
        final start = int.tryParse(mark['start']?.toString() ?? '') ?? 0;
        final end = int.tryParse(mark['end']?.toString() ?? '') ?? 0;
        return switch (mark['type']?.toString().trim()) {
          'bold' => StoryInlineMark.bold(start: start, end: end),
          'italic' => StoryInlineMark.italic(start: start, end: end),
          'underline' => StoryInlineMark.underline(start: start, end: end),
          'strikethrough' => StoryInlineMark.strikethrough(
            start: start,
            end: end,
          ),
          'link' => StoryInlineMark.link(
            start: start,
            end: end,
            url: mark['url']?.toString() ?? '',
          ),
          _ => StoryInlineMark.bold(start: start, end: end),
        };
      })
      .toList(growable: false);
}

StoryImagePayload _imageFromJson(Object? raw) {
  final json = raw is Map ? raw : const <String, Object?>{};
  return StoryImagePayload(fileId: json['fileId']?.toString() ?? '');
}

List<StoryImagePayload> _galleryImagesFromJson(Object? raw) {
  final json = raw is Map ? raw : const <String, Object?>{};
  final images = json['images'];
  if (images is! List) {
    return const [];
  }
  return images.map(_imageFromJson).toList(growable: false);
}

StoryPlaceReference _placeFromJson(Object? raw) {
  final json = raw is Map ? raw : const <String, Object?>{};
  return StoryPlaceReference(
    name: json['name']?.toString() ?? json['placeName']?.toString() ?? '',
    placeId: _normalizeNullable(json['placeId']?.toString()),
    countryCode: _normalizeNullable(
      json['countryCode']?.toString() ?? json['placeCountryCode']?.toString(),
    ),
    cityId: _normalizeNullable(
      json['cityId']?.toString() ?? json['placeCityId']?.toString(),
    ),
    latitude: double.tryParse(json['latitude']?.toString() ?? ''),
    longitude: double.tryParse(json['longitude']?.toString() ?? ''),
  );
}

StoryRouteReference _routeFromJson(Object? raw) {
  final json = raw is Map ? raw : const <String, Object?>{};
  return StoryRouteReference(
    routeId: json['routeId']?.toString() ?? '',
    title: json['title']?.toString() ?? json['routeTitle']?.toString() ?? '',
    description: _normalizeNullable(
      json['description']?.toString() ?? json['routeDescription']?.toString(),
    ),
    profile: _normalizeNullable(
      json['profile']?.toString() ?? json['routeProfile']?.toString(),
    ),
    distanceMeters: int.tryParse(json['distanceMeters']?.toString() ?? ''),
    durationSeconds: int.tryParse(json['durationSeconds']?.toString() ?? ''),
    stopsCount: int.tryParse(json['stopsCount']?.toString() ?? ''),
    shareUrl: _normalizeNullable(json['shareUrl']?.toString()),
  );
}

String _normalizeBlockType(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) {
    return 'paragraph';
  }
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (isUpper && i > 0 && value[i - 1] != '_') {
      buffer.write('_');
    }
    buffer.write(char == '-' ? '_' : char.toLowerCase());
  }
  return buffer.toString();
}

String? _normalizeNullable(String? raw) {
  final value = raw?.trim() ?? '';
  return value.isEmpty ? null : value;
}

List<String> _listItems(String? rawText) {
  return (rawText ?? '')
      .split(RegExp(r'\r?\n'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

StoryImagePayload? _validImage(StoryImagePayload? image) {
  if (image == null) {
    return null;
  }
  return resolvePublicFileContentUrl(image.fileId) == null ? null : image;
}

List<StoryImagePayload> _validGalleryImages(StoryGalleryPayload? gallery) {
  return (gallery?.images ?? const [])
      .where((image) => _validImage(image) != null)
      .toList(growable: false);
}

String _placeTitle(StoryBlock block) {
  final place = block.place;
  if (place == null) {
    return '';
  }
  final name = place.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return (place.placeId ?? '').trim();
}

String _routeTitle(StoryBlock block) {
  final route = block.route;
  if (route == null) {
    return '';
  }
  final title = route.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return route.routeId.trim();
}

String _formatRouteDuration(int seconds, AppLocalizations? l10n) {
  final minutes = (seconds / 60).round().clamp(1, 1440);
  return l10n?.routeDurationMinutesShort(minutes) ?? '$minutes min';
}

String _formatRouteDistance(int meters, AppLocalizations? l10n) {
  if (meters >= 1000) {
    final kilometers = meters / 1000;
    final value = kilometers.toStringAsFixed(kilometers >= 10 ? 0 : 1);
    return l10n?.routeDistanceKilometersShort(value) ?? '$value km';
  }
  return l10n?.routeDistanceMetersShort(meters) ?? '$meters m';
}
