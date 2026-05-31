import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/sticker_api.dart';
import 'package:inflap/features/chat/models/sticker_group_vm.dart';
import 'package:inflap/features/chat/models/sticker_pack_vm.dart';
import 'package:inflap/providers/sticker_catalog_provider.dart';

void main() {
  test('loadCatalog exposes groups and selects first pack', () async {
    final api = _FakeStickerCatalogClient(
      catalog: StickerCatalogResponse(
        version: 7,
        groups: [
          StickerGroupVm(
            id: 'group-1',
            slug: 'travel',
            title: 'Travel',
            packs: [
              StickerPackVm(
                id: 'pack-1',
                slug: 'travel-basics',
                title: const {'en': 'Travel Basics'},
                stickers: const [],
              ),
            ],
          ),
        ],
      ),
    );
    final provider = StickerCatalogProvider(api: api);

    await provider.loadCatalog(locale: 'en');

    expect(provider.isLoading, isFalse);
    expect(provider.groups.single.slug, 'travel');
    expect(provider.selectedPack?.slug, 'travel-basics');
    expect(provider.catalogVersion, 7);
  });

  test('loadCatalog keeps stale catalog when refresh fails', () async {
    final api = _FakeStickerCatalogClient.failAfterFirstSuccess();
    final provider = StickerCatalogProvider(api: api);

    await provider.loadCatalog(locale: 'en');
    await provider.loadCatalog(locale: 'en', forceRefresh: true);

    expect(provider.groups, isNotEmpty);
    expect(provider.error, isNotNull);
    expect(provider.selectedPack?.slug, 'travel-basics');
  });

  test('loadCatalog fetches stickers for selected pack', () async {
    final api = _FakeStickerCatalogClient(
      catalog: StickerCatalogResponse(
        version: 1,
        groups: [
          StickerGroupVm(
            id: 'group-1',
            slug: 'travel',
            title: 'Travel',
            packs: [
              StickerPackVm(
                id: 'pack-1',
                slug: 'travel-basics',
                title: const {'en': 'Travel Basics'},
                stickers: const [],
              ),
            ],
          ),
        ],
      ),
      packStickers: const {
        'pack-1': [
          StickerVm(
            id: 'sticker-1',
            packId: 'pack-1',
            fileId: 'file-1',
            fallbackFileId: 'file-1',
            status: 'active',
          ),
        ],
      },
    );
    final provider = StickerCatalogProvider(api: api);

    await provider.loadCatalog(locale: 'en');

    expect(provider.selectedPack?.stickers.single.id, 'sticker-1');
  });

  test(
    'loadCatalog can preload every pack for instant picker opening',
    () async {
      final api = _FakeStickerCatalogClient(
        catalog: StickerCatalogResponse(
          version: 2,
          groups: [
            StickerGroupVm(
              id: 'group-1',
              slug: 'travel',
              title: 'Travel',
              packs: [
                StickerPackVm(
                  id: 'pack-1',
                  slug: 'travel-basics',
                  title: const {'en': 'Travel Basics'},
                  stickers: const [],
                ),
                StickerPackVm(
                  id: 'pack-2',
                  slug: 'travel-moods',
                  title: const {'en': 'Travel Moods'},
                  stickers: const [],
                ),
              ],
            ),
          ],
        ),
        packStickers: const {
          'pack-1': [
            StickerVm(
              id: 'sticker-1',
              packId: 'pack-1',
              fileId: 'file-1',
              fallbackFileId: 'file-1',
              status: 'active',
            ),
          ],
          'pack-2': [
            StickerVm(
              id: 'sticker-2',
              packId: 'pack-2',
              fileId: 'file-2',
              fallbackFileId: 'file-2',
              status: 'active',
            ),
          ],
        },
      );
      final provider = StickerCatalogProvider(api: api);

      await provider.loadCatalog(locale: 'en', preloadAllPacks: true);

      final packs = provider.groups.single.packs;
      expect(
        packs.expand((pack) => pack.stickers).map((sticker) => sticker.id),
        ['sticker-1', 'sticker-2'],
      );
      expect(api.requestedPackIds, containsAll(['pack-1', 'pack-2']));
    },
  );
}

class _FakeStickerCatalogClient implements StickerCatalogClient {
  _FakeStickerCatalogClient({
    required this._catalog,
    this._packStickers = const {},
  }) : _failAfterFirstSuccess = false;

  _FakeStickerCatalogClient.failAfterFirstSuccess()
    : _catalog = StickerCatalogResponse(
        version: 1,
        groups: [
          StickerGroupVm(
            id: 'group-1',
            slug: 'travel',
            title: 'Travel',
            packs: [
              StickerPackVm(
                id: 'pack-1',
                slug: 'travel-basics',
                title: const {'en': 'Travel Basics'},
                stickers: const [],
              ),
            ],
          ),
        ],
      ),
      _packStickers = const {},
      _failAfterFirstSuccess = true;

  final StickerCatalogResponse _catalog;
  final Map<String, List<StickerVm>> _packStickers;
  final bool _failAfterFirstSuccess;
  final List<String> requestedPackIds = [];
  int _calls = 0;

  @override
  Future<StickerCatalogResponse> listOfficialCatalog({
    required String locale,
  }) async {
    _calls++;
    if (_failAfterFirstSuccess && _calls > 1) {
      throw StateError('network failed');
    }
    return _catalog;
  }

  @override
  Future<List<StickerVm>> listPackStickers(
    String packId, {
    int limit = 50,
    int offset = 0,
  }) async {
    requestedPackIds.add(packId);
    return _packStickers[packId] ?? const [];
  }

  @override
  Future<List<StickerVm>> listRecentStickers({int limit = 40}) async {
    return const [];
  }

  @override
  Future<List<StickerVm>> searchStickers(
    String query, {
    required String locale,
    int limit = 50,
    int offset = 0,
  }) async {
    return const [];
  }
}
