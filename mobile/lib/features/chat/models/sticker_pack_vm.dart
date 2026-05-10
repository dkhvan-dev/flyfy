class StickerPackVm {
  const StickerPackVm({
    required this.id,
    required this.slug,
    this.type = '',
    this.visibility = '',
    this.status = '',
    required this.title,
    this.description = '',
    this.version = 1,
    this.thumbnailFileId = '',
    required this.stickers,
  });

  final String id;
  final String slug;
  final String type;
  final String visibility;
  final String status;
  final Map<String, String> title;
  final String description;
  final int version;
  final String thumbnailFileId;
  final List<StickerVm> stickers;

  String titleFor(String languageCode) {
    final localized = title[languageCode]?.trim() ?? '';
    if (localized.isNotEmpty) return localized;
    final en = title['en']?.trim() ?? '';
    if (en.isNotEmpty) return en;
    return title.values.where((value) => value.trim().isNotEmpty).firstOrNull ??
        slug;
  }

  StickerPackVm copyWith({List<StickerVm>? stickers}) {
    return StickerPackVm(
      id: id,
      slug: slug,
      type: type,
      visibility: visibility,
      status: status,
      title: title,
      description: description,
      version: version,
      thumbnailFileId: thumbnailFileId,
      stickers: stickers ?? this.stickers,
    );
  }

  factory StickerPackVm.fromJson(Map<String, dynamic> json) {
    final title = _localizedMap(json['title']);
    final stickersJson = (json['stickers'] as List<dynamic>?) ?? const [];

    return StickerPackVm(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      title: title,
      description: json['description']?.toString() ?? '',
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      thumbnailFileId: json['thumbnailFileId']?.toString() ?? '',
      stickers: stickersJson
          .whereType<Map<String, dynamic>>()
          .map(StickerVm.fromJson)
          .where(
              (sticker) => sticker.id.isNotEmpty && sticker.fileId.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class StickerVm {
  const StickerVm({
    required this.id,
    required this.packId,
    this.slug = '',
    required this.fileId,
    this.fallbackFileId = '',
    this.previewFileId,
    this.contentType = '',
    this.width = 0,
    this.height = 0,
    this.durationMs = 0,
    this.emoji,
    this.keywords = const [],
    required this.status,
  });

  final String id;
  final String packId;
  final String slug;
  final String fileId;
  final String fallbackFileId;
  final String? previewFileId;
  final String contentType;
  final int width;
  final int height;
  final int durationMs;
  final String? emoji;
  final List<String> keywords;
  final String status;

  factory StickerVm.fromJson(Map<String, dynamic> json) {
    return StickerVm(
      id: json['id']?.toString() ?? '',
      packId: json['packId']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
      fallbackFileId: json['fallbackFileId']?.toString() ?? '',
      previewFileId: json['previewFileId']?.toString(),
      contentType: json['contentType']?.toString() ?? '',
      width: int.tryParse(json['width']?.toString() ?? '') ?? 0,
      height: int.tryParse(json['height']?.toString() ?? '') ?? 0,
      durationMs: int.tryParse(json['durationMs']?.toString() ?? '') ?? 0,
      emoji: json['emoji']?.toString(),
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false) ??
          const [],
      status: json['status']?.toString() ?? '',
    );
  }
}

Map<String, String> _localizedMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }
  final text = value?.toString() ?? '';
  if (text.trim().isEmpty) {
    return const {};
  }
  return {'en': text};
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
