import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../features/chat/models/sticker_pack_vm.dart';
import '../../features/chat/models/sticker_group_vm.dart';
import 'api_client.dart';
import 'file_api.dart';

abstract class StickerCatalogClient {
  Future<StickerCatalogResponse> listOfficialCatalog({
    required String locale,
  });

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
      queryParameters: {
        if (locale.trim().isNotEmpty) 'locale': locale.trim(),
      },
    );
    return StickerCatalogResponse.fromJson(
        response.data as Map<String, dynamic>);
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

  Future<StickerPackVm> ensureCustomPack() async {
    final response = await _apiClient.dio.post('/sticker-packs/my/custom');
    return StickerPackVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> installPack(String packId) async {
    await _apiClient.dio.post('/sticker-packs/${packId.trim()}/install');
  }

  Future<void> removePack(String packId) async {
    await _apiClient.dio.delete('/sticker-packs/${packId.trim()}/install');
  }

  Future<StickerUploadRequestVm> createUploadRequest({
    required String packId,
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    final response = await _apiClient.dio.post(
      '/sticker-packs/${packId.trim()}/upload-requests',
      data: {
        'originalName': originalName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
      },
    );
    return StickerUploadRequestVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> uploadBinary({
    required StickerUploadRequestVm upload,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final fileId = upload.fileId.trim();
    if (fileId.isEmpty) {
      throw ArgumentError.value(
          upload.fileId, 'upload.fileId', 'File id is required');
    }

    // Mobile uploads go through file-manager so clients never depend on
    // Docker-internal or private object storage hostnames from presigned URLs.
    await _apiClient.dio.put<void>(
      '/files/$fileId/binary',
      data: bytes,
      options: Options(
        contentType: contentType,
        headers: {
          'Content-Type': contentType,
        },
        responseType: ResponseType.plain,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
  }

  Future<StickerVm> finalizeUpload({
    required String packId,
    required String uploadSessionId,
    String? emoji,
    List<String> keywords = const [],
  }) async {
    final response = await _apiClient.dio.post(
      '/sticker-packs/${packId.trim()}/uploads/${uploadSessionId.trim()}/finalize',
      data: {
        if ((emoji ?? '').trim().isNotEmpty) 'emoji': emoji!.trim(),
        if (keywords.isNotEmpty) 'keywords': keywords,
      },
    );
    return StickerVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> completeFileUpload(String fileId) async {
    await _apiClient.dio.post('/files/${fileId.trim()}/complete');
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
  const StickerCatalogResponse({
    required this.version,
    required this.groups,
  });

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

class StickerUploadRequestVm {
  const StickerUploadRequestVm({
    required this.uploadSessionId,
    required this.fileId,
    required this.method,
    required this.url,
    required this.headers,
  });

  final String uploadSessionId;
  final String fileId;
  final String method;
  final String url;
  final Map<String, String> headers;

  factory StickerUploadRequestVm.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'] as Map<String, dynamic>? ?? const {};
    return StickerUploadRequestVm(
      uploadSessionId: json['uploadSessionId']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
      method: json['method']?.toString().toUpperCase() ?? 'PUT',
      url: json['url']?.toString() ?? '',
      headers: rawHeaders.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
    );
  }
}
