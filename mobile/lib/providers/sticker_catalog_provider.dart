import 'package:flutter/foundation.dart';

import '../core/network/sticker_api.dart';
import '../features/chat/models/sticker_group_vm.dart';
import '../features/chat/models/sticker_pack_vm.dart';

class StickerCatalogProvider extends ChangeNotifier {
  StickerCatalogProvider({StickerCatalogClient? api})
      : _api = api ?? StickerApi();

  final StickerCatalogClient _api;

  bool _isLoading = false;
  bool _isSearching = false;
  Future<void>? _catalogLoad;
  Object? _error;
  int? _catalogVersion;
  List<StickerGroupVm> _groups = const [];
  StickerPackVm? _selectedPack;
  List<StickerVm> _recentStickers = const [];
  List<StickerVm> _searchResults = const [];

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  Object? get error => _error;
  int? get catalogVersion => _catalogVersion;
  List<StickerGroupVm> get groups => _groups;
  StickerPackVm? get selectedPack => _selectedPack;
  List<StickerVm> get recentStickers => _recentStickers;
  List<StickerVm> get searchResults => _searchResults;

  Future<void> loadCatalog({
    required String locale,
    bool forceRefresh = false,
    bool preloadAllPacks = false,
  }) async {
    if (_groups.isNotEmpty && !forceRefresh) {
      if (preloadAllPacks) {
        await _loadMissingPackStickers();
      }
      return;
    }
    if (_catalogLoad != null && !forceRefresh) {
      await _catalogLoad;
      if (preloadAllPacks) {
        await _loadMissingPackStickers();
      }
      return;
    }

    _catalogLoad = _loadCatalog(
      locale: locale,
      preloadAllPacks: preloadAllPacks,
    );
    await _catalogLoad;
  }

  Future<void> _loadCatalog({
    required String locale,
    required bool preloadAllPacks,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final catalog = await _api.listOfficialCatalog(locale: locale);
      _catalogVersion = catalog.version;
      _groups = catalog.groups;
      _selectedPack = _firstPack(_groups);
      if (_selectedPack != null) {
        await _loadPackStickers(_selectedPack!, notify: false);
      }
      if (preloadAllPacks) {
        await _loadMissingPackStickers(notify: false);
      }
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      _catalogLoad = null;
      notifyListeners();
    }
  }

  Future<void> selectPack(StickerPackVm pack) async {
    _selectedPack = pack;
    _error = null;
    notifyListeners();
    await _loadPackStickers(pack);
  }

  Future<void> loadRecent({int limit = 40}) async {
    try {
      _recentStickers = await _api.listRecentStickers(limit: limit);
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }

  Future<void> search(String query, {required String locale}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _api.searchStickers(
        normalized,
        locale: locale,
      );
    } catch (e) {
      _error = e;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = const [];
    _isSearching = false;
    notifyListeners();
  }

  StickerPackVm? _firstPack(List<StickerGroupVm> groups) {
    for (final group in groups) {
      if (group.packs.isNotEmpty) {
        return group.packs.first;
      }
    }
    return null;
  }

  Future<void> _loadMissingPackStickers({bool notify = true}) async {
    final packs = _groups
        .expand((group) => group.packs)
        .where((pack) => pack.stickers.isEmpty)
        .toList(growable: false);
    if (packs.isEmpty) {
      return;
    }

    try {
      final entries = await Future.wait(
        packs.map((pack) async {
          final stickers = await _api.listPackStickers(pack.id);
          return MapEntry(pack.id, stickers);
        }),
      );
      final stickersByPackID = Map<String, List<StickerVm>>.fromEntries(
        entries,
      );
      _groups = _groups
          .map(
            (group) => group.copyWith(
              packs: group.packs.map((pack) {
                final stickers = stickersByPackID[pack.id];
                return stickers == null
                    ? pack
                    : pack.copyWith(stickers: stickers);
              }).toList(growable: false),
            ),
          )
          .toList(growable: false);
      if (_selectedPack != null) {
        _selectedPack = _findPackByID(_selectedPack!.id) ?? _selectedPack;
      }
    } catch (e) {
      _error = e;
    } finally {
      if (notify) {
        notifyListeners();
      }
    }
  }

  StickerPackVm? _findPackByID(String packID) {
    for (final group in _groups) {
      for (final pack in group.packs) {
        if (pack.id == packID) {
          return pack;
        }
      }
    }
    return null;
  }

  Future<void> _loadPackStickers(
    StickerPackVm pack, {
    bool notify = true,
  }) async {
    if (pack.stickers.isNotEmpty) {
      return;
    }

    try {
      final stickers = await _api.listPackStickers(pack.id);
      final updatedPack = pack.copyWith(stickers: stickers);
      _groups = _groups
          .map(
            (group) => group.copyWith(
              packs: group.packs
                  .map(
                    (item) => item.id == updatedPack.id ? updatedPack : item,
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
      if (_selectedPack?.id == updatedPack.id) {
        _selectedPack = updatedPack;
      }
    } catch (e) {
      _error = e;
    } finally {
      if (notify) {
        notifyListeners();
      }
    }
  }
}
