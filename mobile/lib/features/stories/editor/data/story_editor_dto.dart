import '../domain/story_document.dart';
import 'story_document_mapper.dart';

class StoryEditorWriteRequest {
  StoryEditorWriteRequest({
    required this.title,
    required this.format,
    required this.category,
    required this.status,
    required this.document,
    this.content,
    this.revision,
    this.coverFileId,
    this.placeName,
    this.placeCountryCode,
    this.placeCityId,
    this.tags = const [],
    this.metadata = const {},
  });

  final String title;
  final String format;
  final String category;
  final String status;
  final StoryDocument document;
  final String? content;
  final int? revision;
  final String? coverFileId;
  final String? placeName;
  final String? placeCountryCode;
  final String? placeCityId;
  final List<String> tags;
  final Map<String, Object?> metadata;

  Map<String, dynamic> toJson({String? statusOverride}) {
    final normalizedTags = tags
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final normalizedMetadata = Map<String, Object?>.fromEntries(
      metadata.entries.where((entry) => entry.key.trim().isNotEmpty),
    );
    final blocks = document.blocks
        .map((block) => StoryContentBlockDto.fromBlock(block).toJsonOrNull())
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return {
      'title': title.trim(),
      'format': _upper(format, fallback: 'STORY'),
      'category': _upper(category, fallback: 'JOURNAL'),
      'status': _upper(statusOverride ?? status, fallback: 'DRAFT'),
      'contentSchemaVersion': document.version,
      'contentBlocks': {'version': document.version, 'blocks': blocks},
      'content': _legacyContent,
      if (revision != null) 'revision': revision,
      'coverFileId': _nullableTrim(coverFileId),
      'placeName': _nullableTrim(placeName),
      'placeCountryCode': _nullableCountryCode(placeCountryCode),
      'placeCityId': _nullableTrim(placeCityId),
      'tags': normalizedTags,
      if (normalizedMetadata.isNotEmpty) 'metadata': normalizedMetadata,
    };
  }

  String get _legacyContent {
    final explicitContent = (content ?? '').trim();
    if (explicitContent.isNotEmpty) {
      return explicitContent;
    }
    return StoryDocumentMapper.toLegacyContent(document);
  }
}

class StoryContentBlockDto {
  const StoryContentBlockDto({
    required this.id,
    required this.type,
    this.text,
    this.marks = const [],
    this.level,
    this.image,
    this.gallery,
    this.place,
  });

  factory StoryContentBlockDto.fromBlock(StoryBlock block) {
    return StoryContentBlockDto(
      id: block.id,
      type: _blockTypeToJson(block.type),
      text: block.text,
      marks: block.marks
          .map(StoryInlineMarkDto.fromMark)
          .toList(growable: false),
      level: block.level,
      image: block.image == null
          ? null
          : StoryImagePayloadDto.fromPayload(block.image!),
      gallery: block.gallery == null
          ? null
          : StoryGalleryPayloadDto.fromPayload(block.gallery!),
      place: block.place == null
          ? null
          : StoryPlaceReferenceDto.fromReference(block.place!),
    );
  }

  final String id;
  final String type;
  final String? text;
  final List<StoryInlineMarkDto> marks;
  final int? level;
  final StoryImagePayloadDto? image;
  final StoryGalleryPayloadDto? gallery;
  final StoryPlaceReferenceDto? place;

  Map<String, dynamic>? toJsonOrNull() {
    final base = <String, dynamic>{'id': id, 'type': type};

    switch (type) {
      case 'paragraph':
      case 'quote':
      case 'callout':
        return {
          ...base,
          if ((text ?? '').isNotEmpty) 'text': text,
          if (marks.isNotEmpty) 'marks': _marksJson(),
        };
      case 'heading':
        return {
          ...base,
          if ((text ?? '').isNotEmpty) 'text': text,
          'level': level ?? 1,
          if (marks.isNotEmpty) 'marks': _marksJson(),
        };
      case 'bulleted_list':
      case 'numbered_list':
        final items = _listItemsJson(text);
        if (items.isEmpty) {
          return null;
        }
        return {...base, 'items': items};
      case 'image':
        final payload = image?.toBackendJson();
        return payload == null ? null : {...base, ...payload};
      case 'gallery':
        final payload = gallery?.toBackendJson();
        return payload == null ? null : {...base, ...payload};
      case 'place_reference':
        final payload = place?.toBackendJson();
        return payload == null ? null : {...base, ...payload};
      case 'divider':
        return base;
      default:
        return {
          ...base,
          if ((text ?? '').isNotEmpty) 'text': text,
          if (marks.isNotEmpty) 'marks': _marksJson(),
        };
    }
  }

  Map<String, dynamic> toJson() {
    return toJsonOrNull() ?? {'id': id, 'type': type};
  }

  List<Map<String, dynamic>> _marksJson() {
    return marks.map((mark) => mark.toJson()).toList(growable: false);
  }
}

class StoryInlineMarkDto {
  const StoryInlineMarkDto({
    required this.type,
    required this.start,
    required this.end,
    this.url,
  });

  factory StoryInlineMarkDto.fromMark(StoryInlineMark mark) {
    return StoryInlineMarkDto(
      type: _markTypeToJson(mark.type),
      start: mark.start,
      end: mark.end,
      url: _nullableTrim(mark.url),
    );
  }

  final String type;
  final int start;
  final int end;
  final String? url;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'start': start,
      'end': end,
      if (url != null) 'url': url,
    };
  }
}

class StoryImagePayloadDto {
  const StoryImagePayloadDto({required this.fileId});

  factory StoryImagePayloadDto.fromPayload(StoryImagePayload payload) {
    return StoryImagePayloadDto(fileId: payload.fileId.trim());
  }

  final String fileId;

  Map<String, dynamic> toJson() {
    return {'fileId': fileId};
  }

  Map<String, dynamic>? toBackendJson() {
    final normalizedFileId = _nullableTrim(fileId);
    if (normalizedFileId == null) {
      return null;
    }
    return {'fileId': normalizedFileId};
  }
}

class StoryGalleryPayloadDto {
  StoryGalleryPayloadDto({required List<StoryImagePayloadDto> images})
    : images = List.unmodifiable(images);

  factory StoryGalleryPayloadDto.fromPayload(StoryGalleryPayload payload) {
    return StoryGalleryPayloadDto(
      images: payload.images
          .map(StoryImagePayloadDto.fromPayload)
          .toList(growable: false),
    );
  }

  final List<StoryImagePayloadDto> images;

  Map<String, dynamic> toJson() {
    return {
      'images': images.map((image) => image.toJson()).toList(growable: false),
    };
  }

  Map<String, dynamic>? toBackendJson() {
    final backendImages = images
        .map((image) => image.toBackendJson())
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (backendImages.isEmpty) {
      return null;
    }
    return {'images': backendImages};
  }
}

class StoryPlaceReferenceDto {
  const StoryPlaceReferenceDto({
    required this.name,
    this.placeId,
    this.countryCode,
    this.cityId,
    this.latitude,
    this.longitude,
  });

  factory StoryPlaceReferenceDto.fromReference(StoryPlaceReference reference) {
    return StoryPlaceReferenceDto(
      name: reference.name.trim(),
      placeId: _nullableTrim(reference.placeId),
      countryCode: _nullableCountryCode(reference.countryCode),
      cityId: _nullableTrim(reference.cityId),
      latitude: reference.latitude,
      longitude: reference.longitude,
    );
  }

  final String name;
  final String? placeId;
  final String? countryCode;
  final String? cityId;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (placeId != null) 'placeId': placeId,
      if (countryCode != null) 'countryCode': countryCode,
      if (cityId != null) 'cityId': cityId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  Map<String, dynamic>? toBackendJson() {
    final normalizedName = _nullableTrim(name);
    final normalizedPlaceId = _nullableTrim(placeId);
    if (normalizedName == null && normalizedPlaceId == null) {
      return null;
    }
    return {
      'placeId': ?normalizedPlaceId,
      'placeName': ?normalizedName,
      'placeCountryCode': ?countryCode,
      'placeCityId': ?cityId,
    };
  }
}

class StoryEditorFieldError {
  const StoryEditorFieldError({
    required this.field,
    required this.code,
    required this.message,
    this.blockId,
  });

  factory StoryEditorFieldError.fromJson(Map<String, dynamic> json) {
    return StoryEditorFieldError.fromJsonWithFallbackField(json);
  }

  factory StoryEditorFieldError.fromJsonWithFallbackField(
    Map<String, dynamic> json, {
    String? fallbackField,
  }) {
    return StoryEditorFieldError(
      field: json['field']?.toString() ?? fallbackField ?? '',
      code: json['code']?.toString() ?? 'invalid',
      message: json['message']?.toString() ?? '',
      blockId: _nullableTrim(json['blockId']?.toString()),
    );
  }

  final String field;
  final String code;
  final String message;
  final String? blockId;
}

List<StoryEditorFieldError> parseStoryEditorFieldErrors(Object? data) {
  if (data is! Map<String, dynamic>) {
    return const [];
  }

  final candidates = [
    data['fieldErrors'],
    data['field_errors'],
    data['validationErrors'],
    data['errors'],
  ];

  for (final candidate in candidates) {
    final parsed = _parseFieldErrorCandidate(candidate);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }

  return const [];
}

List<StoryEditorFieldError> _parseFieldErrorCandidate(Object? candidate) {
  if (candidate is List) {
    return candidate
        .whereType<Map<String, dynamic>>()
        .map(StoryEditorFieldError.fromJson)
        .toList(growable: false);
  }

  if (candidate is Map<String, dynamic>) {
    final errors = <StoryEditorFieldError>[];
    for (final entry in candidate.entries) {
      final field = entry.key;
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            errors.add(
              StoryEditorFieldError.fromJsonWithFallbackField(
                item,
                fallbackField: field,
              ),
            );
          } else {
            errors.add(
              StoryEditorFieldError(
                field: field,
                code: item.toString(),
                message: item.toString(),
              ),
            );
          }
        }
      } else if (value != null) {
        errors.add(
          StoryEditorFieldError(
            field: field,
            code: value.toString(),
            message: value.toString(),
          ),
        );
      }
    }
    return errors;
  }

  return const [];
}

String _blockTypeToJson(StoryBlockType type) {
  return switch (type) {
    StoryBlockType.paragraph => 'paragraph',
    StoryBlockType.heading => 'heading',
    StoryBlockType.bulletedList => 'bulleted_list',
    StoryBlockType.numberedList => 'numbered_list',
    StoryBlockType.quote => 'quote',
    StoryBlockType.callout => 'callout',
    StoryBlockType.image => 'image',
    StoryBlockType.gallery => 'gallery',
    StoryBlockType.divider => 'divider',
    StoryBlockType.placeReference => 'place_reference',
  };
}

String _markTypeToJson(StoryInlineMarkType type) {
  return switch (type) {
    StoryInlineMarkType.bold => 'bold',
    StoryInlineMarkType.italic => 'italic',
    StoryInlineMarkType.underline => 'underline',
    StoryInlineMarkType.strikethrough => 'strikethrough',
    StoryInlineMarkType.link => 'link',
  };
}

List<Map<String, dynamic>> _listItemsJson(String? value) {
  return (value ?? '')
      .split(RegExp(r'\r?\n'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .map((item) => {'text': item})
      .toList(growable: false);
}

String _upper(String value, {required String fallback}) {
  final normalized = value.trim().toUpperCase();
  return normalized.isEmpty ? fallback : normalized;
}

String? _nullableCountryCode(String? value) {
  final normalized = value?.trim().toUpperCase() ?? '';
  return normalized.isEmpty ? null : normalized;
}

String? _nullableTrim(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
