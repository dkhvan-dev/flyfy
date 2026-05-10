import '../models/sticker_pack_vm.dart';

List<StickerPackVm> orderStickerPacksForComposer({
  required List<StickerPackVm> myPacks,
  required List<StickerPackVm> officialPacks,
}) {
  final customPacks = myPacks.where(isCustomStickerPack);
  final installedPacks = myPacks.where((pack) => !isCustomStickerPack(pack));
  return _dedupePacks([...customPacks, ...installedPacks, ...officialPacks]);
}

bool isCustomStickerPack(StickerPackVm pack) {
  final type = pack.type.trim().toUpperCase();
  if (type == 'USER_CUSTOM') return true;

  final slug = pack.slug.trim().toLowerCase();
  if (slug.startsWith('custom-')) return true;

  return false;
}

List<StickerPackVm> _dedupePacks(List<StickerPackVm> packs) {
  final seen = <String>{};
  final result = <StickerPackVm>[];
  for (final pack in packs) {
    final id = pack.id.trim();
    if (id.isEmpty || !seen.add(id)) continue;
    result.add(pack);
  }
  return result;
}
