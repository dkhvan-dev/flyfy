import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/chat/models/sticker_pack_vm.dart';
import 'package:inflap/features/chat/utils/sticker_pack_ordering.dart';

void main() {
  test('omits custom stickers from composer packs', () {
    final ordered = orderStickerPacksForComposer(
      myPacks: [
        const StickerPackVm(
          id: 'installed-pack',
          slug: 'travel-basics',
          type: 'OFFICIAL',
          title: {'en': 'Travel Basics'},
          stickers: [],
        ),
        const StickerPackVm(
          id: 'custom-pack',
          slug: 'custom-user-1',
          type: 'USER_CUSTOM',
          title: {'en': 'My stickers', 'ru': 'Мои стикеры'},
          stickers: [],
        ),
      ],
      officialPacks: [
        const StickerPackVm(
          id: 'official-pack',
          slug: 'flight-moods',
          type: 'OFFICIAL',
          title: {'en': 'Flight Moods'},
          stickers: [],
        ),
      ],
    );

    expect(ordered.map((pack) => pack.id), ['installed-pack', 'official-pack']);
  });

  test('keeps user pack version when it duplicates an official pack', () {
    final ordered = orderStickerPacksForComposer(
      myPacks: [
        const StickerPackVm(
          id: 'official-pack',
          slug: 'travel-basics-installed',
          type: 'OFFICIAL',
          title: {'en': 'Installed Travel Basics'},
          stickers: [],
        ),
      ],
      officialPacks: [
        const StickerPackVm(
          id: 'official-pack',
          slug: 'travel-basics',
          type: 'OFFICIAL',
          title: {'en': 'Travel Basics'},
          stickers: [],
        ),
      ],
    );

    expect(ordered, hasLength(1));
    expect(ordered.single.slug, 'travel-basics-installed');
  });
}
