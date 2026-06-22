enum StoryBlockType {
  paragraph,
  heading,
  bulletedList,
  numberedList,
  quote,
  callout,
  image,
  gallery,
  divider,
  placeReference,
  routeReference,
}

enum StoryInlineMarkType { bold, italic, underline, strikethrough, link }

enum StoryUploadState { complete, uploading, failed }

class StoryDocumentLimits {
  const StoryDocumentLimits._();

  static const int maxTextBlockLength = 5000;
  static const int maxHeadingLength = 160;
  static const int maxCalloutLength = 800;
  static const int maxQuoteLength = 1200;
  static const int maxPlainTextLength = 20000;
}

class StoryInlineMark {
  const StoryInlineMark({
    required this.type,
    required this.start,
    required this.end,
    this.url,
  });

  const StoryInlineMark.bold({required int start, required int end})
    : this(type: StoryInlineMarkType.bold, start: start, end: end);

  const StoryInlineMark.italic({required int start, required int end})
    : this(type: StoryInlineMarkType.italic, start: start, end: end);

  const StoryInlineMark.underline({required int start, required int end})
    : this(type: StoryInlineMarkType.underline, start: start, end: end);

  const StoryInlineMark.strikethrough({required int start, required int end})
    : this(type: StoryInlineMarkType.strikethrough, start: start, end: end);

  const StoryInlineMark.link({
    required int start,
    required int end,
    required String url,
  }) : this(type: StoryInlineMarkType.link, start: start, end: end, url: url);

  final StoryInlineMarkType type;
  final int start;
  final int end;
  final String? url;

  StoryInlineMark copyWith({
    StoryInlineMarkType? type,
    int? start,
    int? end,
    String? url,
    bool clearUrl = false,
  }) {
    return StoryInlineMark(
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      url: clearUrl ? null : url ?? this.url,
    );
  }
}

class StoryImagePayload {
  const StoryImagePayload({
    required this.fileId,
    this.uploadState = StoryUploadState.complete,
  });

  final String fileId;
  final StoryUploadState uploadState;

  bool get hasFileId => fileId.trim().isNotEmpty;

  bool get isUploadComplete =>
      uploadState == StoryUploadState.complete && hasFileId;

  StoryImagePayload copyWith({String? fileId, StoryUploadState? uploadState}) {
    return StoryImagePayload(
      fileId: fileId ?? this.fileId,
      uploadState: uploadState ?? this.uploadState,
    );
  }
}

class StoryGalleryPayload {
  StoryGalleryPayload({required List<StoryImagePayload> images})
    : _images = List.unmodifiable(images);

  final List<StoryImagePayload> _images;

  List<StoryImagePayload> get images => _images;

  bool get isUploadComplete => _images.every((image) => image.isUploadComplete);

  StoryGalleryPayload copyWith({List<StoryImagePayload>? images}) {
    return StoryGalleryPayload(images: images ?? _images);
  }
}

class StoryPlaceReference {
  const StoryPlaceReference({
    required this.name,
    this.placeId,
    this.countryCode,
    this.cityId,
    this.latitude,
    this.longitude,
  });

  final String? placeId;
  final String name;
  final String? countryCode;
  final String? cityId;
  final double? latitude;
  final double? longitude;

  bool get isMeaningful =>
      name.trim().isNotEmpty || (placeId ?? '').trim().isNotEmpty;

  StoryPlaceReference copyWith({
    String? placeId,
    String? name,
    String? countryCode,
    String? cityId,
    double? latitude,
    double? longitude,
    bool clearPlaceId = false,
    bool clearCountryCode = false,
    bool clearCityId = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
  }) {
    return StoryPlaceReference(
      placeId: clearPlaceId ? null : placeId ?? this.placeId,
      name: name ?? this.name,
      countryCode: clearCountryCode ? null : countryCode ?? this.countryCode,
      cityId: clearCityId ? null : cityId ?? this.cityId,
      latitude: clearLatitude ? null : latitude ?? this.latitude,
      longitude: clearLongitude ? null : longitude ?? this.longitude,
    );
  }
}

class StoryRouteReference {
  const StoryRouteReference({
    required this.routeId,
    required this.title,
    this.description,
    this.profile,
    this.distanceMeters,
    this.durationSeconds,
    this.stopsCount,
    this.shareUrl,
  });

  final String routeId;
  final String title;
  final String? description;
  final String? profile;
  final int? distanceMeters;
  final int? durationSeconds;
  final int? stopsCount;
  final String? shareUrl;

  bool get isMeaningful => routeId.trim().isNotEmpty && title.trim().isNotEmpty;

  StoryRouteReference copyWith({
    String? routeId,
    String? title,
    String? description,
    String? profile,
    int? distanceMeters,
    int? durationSeconds,
    int? stopsCount,
    String? shareUrl,
    bool clearDescription = false,
    bool clearProfile = false,
    bool clearDistanceMeters = false,
    bool clearDurationSeconds = false,
    bool clearStopsCount = false,
    bool clearShareUrl = false,
  }) {
    return StoryRouteReference(
      routeId: routeId ?? this.routeId,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      profile: clearProfile ? null : profile ?? this.profile,
      distanceMeters: clearDistanceMeters
          ? null
          : distanceMeters ?? this.distanceMeters,
      durationSeconds: clearDurationSeconds
          ? null
          : durationSeconds ?? this.durationSeconds,
      stopsCount: clearStopsCount ? null : stopsCount ?? this.stopsCount,
      shareUrl: clearShareUrl ? null : shareUrl ?? this.shareUrl,
    );
  }
}

class StoryBlock {
  StoryBlock._({
    required this.id,
    required this.type,
    this.text,
    List<StoryInlineMark> marks = const [],
    this.level,
    this.image,
    this.gallery,
    this.place,
    this.route,
  }) : _marks = List.unmodifiable(marks);

  factory StoryBlock.paragraph({
    required String id,
    required String text,
    List<StoryInlineMark> marks = const [],
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.paragraph,
      text: text,
      marks: marks,
    );
  }

  factory StoryBlock.heading({
    required String id,
    required String text,
    int level = 1,
    List<StoryInlineMark> marks = const [],
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.heading,
      text: text,
      marks: marks,
      level: level,
    );
  }

  factory StoryBlock.bulletedList({
    required String id,
    required String text,
    List<StoryInlineMark> marks = const [],
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.bulletedList,
      text: text,
      marks: marks,
    );
  }

  factory StoryBlock.numberedList({
    required String id,
    required String text,
    List<StoryInlineMark> marks = const [],
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.numberedList,
      text: text,
      marks: marks,
    );
  }

  factory StoryBlock.quote({
    required String id,
    required String text,
    List<StoryInlineMark> marks = const [],
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.quote,
      text: text,
      marks: marks,
    );
  }

  factory StoryBlock.callout({
    required String id,
    required String text,
    List<StoryInlineMark> marks = const [],
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.callout,
      text: text,
      marks: marks,
    );
  }

  factory StoryBlock.image({
    required String id,
    required StoryImagePayload image,
  }) {
    return StoryBlock._(id: id, type: StoryBlockType.image, image: image);
  }

  factory StoryBlock.gallery({
    required String id,
    required StoryGalleryPayload gallery,
  }) {
    return StoryBlock._(id: id, type: StoryBlockType.gallery, gallery: gallery);
  }

  factory StoryBlock.divider({required String id}) {
    return StoryBlock._(id: id, type: StoryBlockType.divider);
  }

  factory StoryBlock.placeReference({
    required String id,
    required StoryPlaceReference place,
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.placeReference,
      place: place,
    );
  }

  factory StoryBlock.routeReference({
    required String id,
    required StoryRouteReference route,
  }) {
    return StoryBlock._(
      id: id,
      type: StoryBlockType.routeReference,
      route: route,
    );
  }

  final String id;
  final StoryBlockType type;
  final String? text;
  final List<StoryInlineMark> _marks;
  final int? level;
  final StoryImagePayload? image;
  final StoryGalleryPayload? gallery;
  final StoryPlaceReference? place;
  final StoryRouteReference? route;

  List<StoryInlineMark> get marks => _marks;

  bool get isTextBlock {
    return switch (type) {
      StoryBlockType.paragraph ||
      StoryBlockType.heading ||
      StoryBlockType.bulletedList ||
      StoryBlockType.numberedList ||
      StoryBlockType.quote ||
      StoryBlockType.callout => true,
      StoryBlockType.image ||
      StoryBlockType.gallery ||
      StoryBlockType.divider ||
      StoryBlockType.placeReference ||
      StoryBlockType.routeReference => false,
    };
  }

  StoryBlock copyWith({
    String? id,
    String? text,
    List<StoryInlineMark>? marks,
    int? level,
    StoryImagePayload? image,
    StoryGalleryPayload? gallery,
    StoryPlaceReference? place,
    StoryRouteReference? route,
    bool clearText = false,
  }) {
    final nextId = id ?? this.id;
    final nextText = clearText ? '' : text ?? this.text ?? '';
    final nextMarks = marks ?? this.marks;
    return switch (type) {
      StoryBlockType.paragraph => StoryBlock.paragraph(
        id: nextId,
        text: nextText,
        marks: nextMarks,
      ),
      StoryBlockType.heading => StoryBlock.heading(
        id: nextId,
        text: nextText,
        level: level ?? this.level ?? 1,
        marks: nextMarks,
      ),
      StoryBlockType.bulletedList => StoryBlock.bulletedList(
        id: nextId,
        text: nextText,
        marks: nextMarks,
      ),
      StoryBlockType.numberedList => StoryBlock.numberedList(
        id: nextId,
        text: nextText,
        marks: nextMarks,
      ),
      StoryBlockType.quote => StoryBlock.quote(
        id: nextId,
        text: nextText,
        marks: nextMarks,
      ),
      StoryBlockType.callout => StoryBlock.callout(
        id: nextId,
        text: nextText,
        marks: nextMarks,
      ),
      StoryBlockType.image => StoryBlock.image(
        id: nextId,
        image: image ?? this.image!,
      ),
      StoryBlockType.gallery => StoryBlock.gallery(
        id: nextId,
        gallery: gallery ?? this.gallery!,
      ),
      StoryBlockType.divider => StoryBlock.divider(id: nextId),
      StoryBlockType.placeReference => StoryBlock.placeReference(
        id: nextId,
        place: place ?? this.place!,
      ),
      StoryBlockType.routeReference => StoryBlock.routeReference(
        id: nextId,
        route: route ?? this.route!,
      ),
    };
  }
}

class StoryValidationIssue {
  const StoryValidationIssue({
    required this.code,
    required this.message,
    this.blockId,
  });

  final String code;
  final String message;
  final String? blockId;
}

class StoryValidationResult {
  StoryValidationResult(List<StoryValidationIssue> issues)
    : issues = List.unmodifiable(issues);

  final List<StoryValidationIssue> issues;

  bool get isValid => issues.isEmpty;

  List<String> get codes =>
      issues.map((issue) => issue.code).toList(growable: false);
}

class StoryDocument {
  StoryDocument({
    this.version = currentVersion,
    List<StoryBlock> blocks = const [],
  }) : _blocks = List.unmodifiable(blocks);

  static const int currentVersion = 1;

  final int version;
  final List<StoryBlock> _blocks;

  List<StoryBlock> get blocks => _blocks;

  bool get isDraftSaveable => validateForDraft().isValid;

  bool get isUploadComplete {
    for (final block in _blocks) {
      if (block.type == StoryBlockType.image &&
          !(block.image?.isUploadComplete ?? false)) {
        return false;
      }
      if (block.type == StoryBlockType.gallery &&
          !(block.gallery?.isUploadComplete ?? false)) {
        return false;
      }
    }
    return true;
  }

  bool get isPublishReady => validateForPublish().isValid;

  String get plainText {
    final parts = <String>[];
    for (final block in _blocks) {
      if (block.isTextBlock) {
        final value = (block.text ?? '').trim();
        if (value.isNotEmpty) {
          parts.add(value);
        }
      } else if (block.type == StoryBlockType.placeReference) {
        final name = (block.place?.name ?? '').trim();
        if (name.isNotEmpty) {
          parts.add(name);
        }
      } else if (block.type == StoryBlockType.routeReference) {
        final title = (block.route?.title ?? '').trim();
        if (title.isNotEmpty) {
          parts.add(title);
        }
      }
    }
    return parts.join('\n\n');
  }

  StoryBlock? blockById(String id) {
    if (!_isCanonicalBlockId(id)) {
      return null;
    }
    final target = id;
    for (final block in _blocks) {
      if (block.id == target) {
        return block;
      }
    }
    return null;
  }

  StoryDocument copyWith({int? version, List<StoryBlock>? blocks}) {
    return StoryDocument(
      version: version ?? this.version,
      blocks: blocks ?? _blocks,
    );
  }

  StoryDocument appendBlock(StoryBlock block) {
    return copyWith(blocks: [..._blocks, block]);
  }

  StoryDocument insertBlock(int index, StoryBlock block) {
    final next = [..._blocks];
    next.insert(index.clamp(0, next.length), block);
    return copyWith(blocks: next);
  }

  StoryDocument replaceBlock(String blockId, StoryBlock replacement) {
    return updateBlock(blockId, (_) => replacement);
  }

  StoryDocument updateBlock(
    String blockId,
    StoryBlock Function(StoryBlock block) update,
  ) {
    if (!_isCanonicalBlockId(blockId)) {
      return this;
    }
    var changed = false;
    final next = _blocks
        .map((block) {
          if (block.id != blockId) {
            return block;
          }
          changed = true;
          return update(block);
        })
        .toList(growable: false);
    return changed ? copyWith(blocks: next) : this;
  }

  StoryDocument removeBlock(String blockId) {
    if (!_isCanonicalBlockId(blockId)) {
      return this;
    }
    final next = _blocks
        .where((block) => block.id != blockId)
        .toList(growable: false);
    return next.length == _blocks.length ? this : copyWith(blocks: next);
  }

  StoryDocument moveBlock(String blockId, int newIndex) {
    if (!_isCanonicalBlockId(blockId)) {
      return this;
    }
    final currentIndex = _blocks.indexWhere((block) => block.id == blockId);
    if (currentIndex < 0) {
      return this;
    }
    final next = [..._blocks];
    final block = next.removeAt(currentIndex);
    next.insert(newIndex.clamp(0, next.length), block);
    return copyWith(blocks: next);
  }

  StoryValidationResult validateForDraft() {
    return StoryValidationResult(_validate(requirePublishReady: false));
  }

  StoryValidationResult validateForPublish() {
    return StoryValidationResult(_validate(requirePublishReady: true));
  }

  List<StoryValidationIssue> _validate({required bool requirePublishReady}) {
    final issues = <StoryValidationIssue>[];
    if (version != currentVersion) {
      issues.add(
        const StoryValidationIssue(
          code: 'invalid_version',
          message: 'Story document version is not supported.',
        ),
      );
    }

    final seenIds = <String>{};
    for (final block in _blocks) {
      final blockId = block.id.trim();
      if (blockId.isEmpty) {
        issues.add(
          const StoryValidationIssue(
            code: 'block_id_required',
            message: 'Story block id is required.',
          ),
        );
      } else if (!_isCanonicalBlockId(block.id)) {
        issues.add(
          StoryValidationIssue(
            code: 'block_id_invalid',
            message: 'Story block id must be trimmed and canonical.',
            blockId: block.id,
          ),
        );
      } else if (!seenIds.add(blockId)) {
        issues.add(
          StoryValidationIssue(
            code: 'duplicate_block_id',
            message: 'Story block id must be unique.',
            blockId: block.id,
          ),
        );
      }
      _validateBlock(block, issues, requireUploadComplete: requirePublishReady);
    }

    if (plainText.length > StoryDocumentLimits.maxPlainTextLength) {
      issues.add(
        const StoryValidationIssue(
          code: 'content_too_long',
          message: 'Story content is too long.',
        ),
      );
    }

    if (requirePublishReady) {
      if (!_hasPublishableContent) {
        issues.add(
          const StoryValidationIssue(
            code: 'content_required',
            message: 'Publishable story content is required.',
          ),
        );
      }
      if (!isUploadComplete) {
        issues.add(
          const StoryValidationIssue(
            code: 'upload_incomplete',
            message: 'All story media uploads must complete before publishing.',
          ),
        );
      }
    }

    return issues;
  }

  void _validateBlock(
    StoryBlock block,
    List<StoryValidationIssue> issues, {
    required bool requireUploadComplete,
  }) {
    if (block.isTextBlock) {
      _validateTextBlock(block, issues);
      return;
    }

    switch (block.type) {
      case StoryBlockType.image:
        final image = block.image;
        if (image == null) {
          issues.add(
            StoryValidationIssue(
              code: 'image_payload_required',
              message: 'Image block requires an image payload.',
              blockId: block.id,
            ),
          );
        } else {
          _validateImagePayload(
            image,
            issues,
            block.id,
            requireUploadComplete: requireUploadComplete,
          );
        }
      case StoryBlockType.gallery:
        final gallery = block.gallery;
        if (gallery == null || gallery.images.isEmpty) {
          issues.add(
            StoryValidationIssue(
              code: 'gallery_images_required',
              message: 'Gallery block requires at least one image.',
              blockId: block.id,
            ),
          );
        } else {
          for (final image in gallery.images) {
            _validateImagePayload(
              image,
              issues,
              block.id,
              requireUploadComplete: requireUploadComplete,
            );
          }
        }
      case StoryBlockType.placeReference:
        if (!(block.place?.isMeaningful ?? false)) {
          issues.add(
            StoryValidationIssue(
              code: 'place_reference_required',
              message: 'Place reference block requires a place.',
              blockId: block.id,
            ),
          );
        }
      case StoryBlockType.routeReference:
        final route = block.route;
        if (!(route?.isMeaningful ?? false)) {
          issues.add(
            StoryValidationIssue(
              code: 'route_reference_required',
              message: 'Route reference block requires a route.',
              blockId: block.id,
            ),
          );
        } else {
          _validateRouteReference(route!, issues, block.id);
        }
      case StoryBlockType.divider:
        break;
      case StoryBlockType.paragraph:
      case StoryBlockType.heading:
      case StoryBlockType.bulletedList:
      case StoryBlockType.numberedList:
      case StoryBlockType.quote:
      case StoryBlockType.callout:
        break;
    }
  }

  void _validateRouteReference(
    StoryRouteReference route,
    List<StoryValidationIssue> issues,
    String blockId,
  ) {
    if (route.distanceMeters != null && route.distanceMeters! < 0) {
      issues.add(
        StoryValidationIssue(
          code: 'route_reference_distance_invalid',
          message: 'Route reference distance must be non-negative.',
          blockId: blockId,
        ),
      );
    }
    if (route.durationSeconds != null && route.durationSeconds! < 0) {
      issues.add(
        StoryValidationIssue(
          code: 'route_reference_duration_invalid',
          message: 'Route reference duration must be non-negative.',
          blockId: blockId,
        ),
      );
    }
    if (route.stopsCount != null && route.stopsCount! < 0) {
      issues.add(
        StoryValidationIssue(
          code: 'route_reference_stops_invalid',
          message: 'Route reference stops count must be non-negative.',
          blockId: blockId,
        ),
      );
    }
    final shareUrl = route.shareUrl?.trim() ?? '';
    if (shareUrl.isNotEmpty && !_isSafeLinkUrl(shareUrl)) {
      issues.add(
        StoryValidationIssue(
          code: 'route_reference_share_url_invalid',
          message: 'Route reference share URL must use http or https.',
          blockId: blockId,
        ),
      );
    }
  }

  void _validateTextBlock(StoryBlock block, List<StoryValidationIssue> issues) {
    final text = block.text ?? '';
    final maxLength = switch (block.type) {
      StoryBlockType.heading => StoryDocumentLimits.maxHeadingLength,
      StoryBlockType.callout => StoryDocumentLimits.maxCalloutLength,
      StoryBlockType.quote => StoryDocumentLimits.maxQuoteLength,
      _ => StoryDocumentLimits.maxTextBlockLength,
    };
    if (text.length > maxLength) {
      issues.add(
        StoryValidationIssue(
          code: 'text_too_long',
          message: 'Story block text is too long.',
          blockId: block.id,
        ),
      );
    }
    if (block.type == StoryBlockType.heading) {
      final level = block.level ?? 1;
      if (level < 1 || level > 3) {
        issues.add(
          StoryValidationIssue(
            code: 'heading_level_invalid',
            message: 'Heading level must be between 1 and 3.',
            blockId: block.id,
          ),
        );
      }
    }
    for (final mark in block.marks) {
      if (mark.start < 0 || mark.end <= mark.start || mark.end > text.length) {
        issues.add(
          StoryValidationIssue(
            code: 'mark_range_invalid',
            message: 'Inline mark range is outside the block text.',
            blockId: block.id,
          ),
        );
      }
      if (mark.type == StoryInlineMarkType.link &&
          !_isSafeLinkUrl(mark.url ?? '')) {
        issues.add(
          StoryValidationIssue(
            code: 'unsafe_link',
            message: 'Link marks only support http and https URLs.',
            blockId: block.id,
          ),
        );
      }
    }
  }

  void _validateImagePayload(
    StoryImagePayload image,
    List<StoryValidationIssue> issues,
    String blockId, {
    required bool requireUploadComplete,
  }) {
    if (image.uploadState == StoryUploadState.complete && !image.hasFileId) {
      issues.add(
        StoryValidationIssue(
          code: 'image_file_id_required',
          message: 'Completed image uploads require a file id.',
          blockId: blockId,
        ),
      );
    }
    if (requireUploadComplete && !image.isUploadComplete) {
      issues.add(
        StoryValidationIssue(
          code: 'image_upload_incomplete',
          message: 'Image upload must complete before publishing.',
          blockId: blockId,
        ),
      );
    }
  }

  bool get _hasPublishableContent {
    for (final block in _blocks) {
      if (block.isTextBlock && (block.text ?? '').trim().isNotEmpty) {
        return true;
      }
      if (block.type == StoryBlockType.image &&
          (block.image?.isUploadComplete ?? false)) {
        return true;
      }
      if (block.type == StoryBlockType.gallery &&
          (block.gallery?.images.any((image) => image.isUploadComplete) ??
              false)) {
        return true;
      }
      if (block.type == StoryBlockType.placeReference &&
          (block.place?.isMeaningful ?? false)) {
        return true;
      }
      if (block.type == StoryBlockType.routeReference &&
          (block.route?.isMeaningful ?? false)) {
        return true;
      }
    }
    return false;
  }

  bool _isSafeLinkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && (uri.host.isNotEmpty);
  }

  bool _isCanonicalBlockId(String value) {
    return value.isNotEmpty && value.trim() == value;
  }
}
