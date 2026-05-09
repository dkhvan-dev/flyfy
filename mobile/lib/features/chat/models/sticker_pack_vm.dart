class StickerPackVm {
  const StickerPackVm({
    required this.id,
    required this.slug,
    required this.type,
    required this.visibility,
    required this.status,
    required this.title,
    required this.stickers,
  });

  final String id;
  final String slug;
  final String type;
  final String visibility;
  final String status;
  final Map<String, String> title;
  final List<StickerVm> stickers;

  String titleFor(String languageCode) {
    final localized = title[languageCode]?.trim() ?? '';
    if (localized.isNotEmpty) return localized;
    final en = title['en']?.trim() ?? '';
    if (en.isNotEmpty) return en;
    return title.values.where((value) => value.trim().isNotEmpty).firstOrNull ??
        slug;
  }

  factory StickerPackVm.fromJson(Map<String, dynamic> json) {
    final titleJson = json['title'] as Map<String, dynamic>? ?? const {};
    final stickersJson = (json['stickers'] as List<dynamic>?) ?? const [];

    return StickerPackVm(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      title: titleJson.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
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
    required this.fileId,
    this.emoji,
    this.keywords = const [],
    required this.status,
  });

  final String id;
  final String packId;
  final String fileId;
  final String? emoji;
  final List<String> keywords;
  final String status;

  factory StickerVm.fromJson(Map<String, dynamic> json) {
    return StickerVm(
      id: json['id']?.toString() ?? '',
      packId: json['packId']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
