import 'sticker_pack_vm.dart';

class StickerGroupVm {
  const StickerGroupVm({
    required this.id,
    required this.slug,
    required this.title,
    required this.packs,
  });

  final String id;
  final String slug;
  final String title;
  final List<StickerPackVm> packs;

  StickerGroupVm copyWith({List<StickerPackVm>? packs}) {
    return StickerGroupVm(
      id: id,
      slug: slug,
      title: title,
      packs: packs ?? this.packs,
    );
  }

  factory StickerGroupVm.fromJson(Map<String, dynamic> json) {
    final packsJson = (json['packs'] as List<dynamic>?) ?? const [];
    return StickerGroupVm(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      packs: packsJson
          .whereType<Map<String, dynamic>>()
          .map(StickerPackVm.fromJson)
          .where((pack) => pack.id.isNotEmpty)
          .toList(growable: false),
    );
  }
}
