import 'package:dio/dio.dart';

import '../../features/chat/models/sticker_pack_vm.dart';
import '../../features/chat/models/sticker_group_vm.dart';
import 'api_client.dart';
import 'file_api.dart';

abstract class StickerCatalogClient {
  Future<StickerCatalogResponse> listOfficialCatalog({required String locale});

  Future<List<StickerVm>> listPackStickers(
    String packId, {
    int limit = 50,
    int offset = 0,
  });

  Future<List<StickerVm>> searchStickers(
    String query, {
    required String locale,
    int limit = 50,
    int offset = 0,
  });

  Future<List<StickerVm>> listRecentStickers({int limit = 40});
}

class StickerApi implements StickerCatalogClient {
  StickerApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<StickerCatalogResponse> listOfficialCatalog({
    required String locale,
  }) async {
    final response = await _apiClient.dio.get(
      '/stickers/catalog',
      queryParameters: {if (locale.trim().isNotEmpty) 'locale': locale.trim()},
    );
    return StickerCatalogResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<StickerVm>> listPackStickers(
    String packId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/stickers/packs/${packId.trim()}/stickers',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return _parseStickers(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<StickerVm>> searchStickers(
    String query, {
    required String locale,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/stickers/search',
      queryParameters: {
        'q': query.trim(),
        if (locale.trim().isNotEmpty) 'locale': locale.trim(),
        'limit': limit,
        'offset': offset,
      },
    );
    return _parseStickers(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<StickerVm>> listRecentStickers({int limit = 40}) async {
    final response = await _apiClient.dio.get(
      '/stickers/recent',
      queryParameters: {'limit': limit},
    );
    return _parseStickers(response.data as Map<String, dynamic>);
  }

  Future<List<StickerPackVm>> listDefaultPacks() async {
    final response = await _apiClient.dio.get(
      '/sticker-packs/default',
      options: Options(extra: {'requiresAuth': false}),
    );
    return _parsePacks(response.data as Map<String, dynamic>);
  }

  Future<List<StickerPackVm>> listMyPacks() async {
    final response = await _apiClient.dio.get('/sticker-packs/my');
    return _parsePacks(response.data as Map<String, dynamic>);
  }

  Future<void> installPack(String packId) async {
    await _apiClient.dio.post('/sticker-packs/${packId.trim()}/install');
  }

  Future<void> removePack(String packId) async {
    await _apiClient.dio.delete('/sticker-packs/${packId.trim()}/install');
  }

  String? publicContentUrl(String fileId) =>
      resolvePublicFileContentUrl(fileId);

  List<StickerPackVm> _parsePacks(Map<String, dynamic> json) {
    final items = (json['packs'] as List<dynamic>?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(StickerPackVm.fromJson)
        .where((pack) => pack.id.isNotEmpty)
        .toList(growable: false);
  }

  List<StickerVm> _parseStickers(Map<String, dynamic> json) {
    final items = (json['stickers'] as List<dynamic>?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(StickerVm.fromJson)
        .where((sticker) => sticker.id.isNotEmpty)
        .toList(growable: false);
  }
}

class StickerCatalogResponse {
  const StickerCatalogResponse({required this.version, required this.groups});

  final int version;
  final List<StickerGroupVm> groups;

  factory StickerCatalogResponse.fromJson(Map<String, dynamic> json) {
    final groupsJson = (json['groups'] as List<dynamic>?) ?? const [];
    return StickerCatalogResponse(
      version: int.tryParse(json['version']?.toString() ?? '') ?? 0,
      groups: groupsJson
          .whereType<Map<String, dynamic>>()
          .map(StickerGroupVm.fromJson)
          .where((group) => group.id.isNotEmpty)
          .toList(growable: false),
    );
  }
}
