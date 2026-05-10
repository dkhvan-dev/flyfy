import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';

String? resolvePublicFileContentUrl(String fileId) {
  final trimmed = fileId.trim();
  if (trimmed.isEmpty || trimmed == '00000000-0000-0000-0000-000000000000') {
    return null;
  }
  return '${AppConfig.apiBaseUrl}/public/files/$trimmed/content';
}

class FileApi {
  FileApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<FileUploadRequestVm> createActivityMediaUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'ACTIVITY_MEDIA',
      visibility: 'PROTECTED',
    );
  }

  Future<FileUploadRequestVm> createStoryCoverUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'ACTIVITY_MEDIA',
      visibility: 'PUBLIC',
    );
  }

  Future<FileUploadRequestVm> createStoryInlineImageUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'ACTIVITY_MEDIA',
      visibility: 'PUBLIC',
    );
  }

  Future<FileUploadRequestVm> createAttractionReviewMediaUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'ATTRACTION_REVIEW_MEDIA',
      visibility: 'PUBLIC',
    );
  }

  Future<FileUploadRequestVm> createAttractionMediaUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'ATTRACTION_MEDIA',
      visibility: 'PUBLIC',
    );
  }

  Future<FileUploadRequestVm> createTourCoverUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'TOUR_MEDIA',
      visibility: 'PUBLIC',
    );
  }

  Future<FileUploadRequestVm> createAvatarUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'AVATAR',
      visibility: 'PUBLIC',
    );
  }

  Future<FileUploadRequestVm> createGuideVerificationUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'GUIDE_VERIFICATION_DOC',
      visibility: 'PROTECTED',
    );
  }

  Future<FileUploadRequestVm> createChatAttachmentUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'CHAT_ATTACHMENT',
      visibility: 'PROTECTED',
    );
  }

  Future<FileUploadRequestVm> createChatStickerUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    return _createUploadRequest(
      originalName: originalName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      purpose: 'CHAT_STICKER',
      visibility: 'PROTECTED',
    );
  }

  Future<FileUploadRequestVm> _createUploadRequest({
    required String originalName,
    required String contentType,
    required int sizeBytes,
    required String purpose,
    required String visibility,
  }) async {
    final response = await _apiClient.dio.post(
      '/files/upload-requests',
      data: {
        'originalName': originalName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'purpose': purpose,
        'visibility': visibility,
      },
    );

    return FileUploadRequestVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> uploadBinary({
    required FileUploadRequestVm upload,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _apiClient.dio.put<void>(
      '/files/${upload.fileId}/binary',
      data: bytes,
      options: Options(
        contentType: contentType,
        headers: {'Content-Type': contentType},
        responseType: ResponseType.plain,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
  }

  Future<void> completeUpload(String fileId) async {
    await _apiClient.dio.post('/files/$fileId/complete');
  }

  Future<String?> createDownloadUrl(String fileId) async {
    final trimmed = fileId.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final response = await _apiClient.createFileDownloadUrl(trimmed);
    final url = response['url']?.toString().trim() ?? '';
    return url.isEmpty ? null : url;
  }

  Future<FileContentVm> downloadContent(String fileId) async {
    final trimmed = fileId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(fileId, 'fileId', 'File id is required');
    }

    final response = await _apiClient.dio.get<List<int>>(
      '/files/$trimmed/content',
      options: Options(responseType: ResponseType.bytes),
    );
    return FileContentVm(
      bytes: Uint8List.fromList(response.data ?? const <int>[]),
      contentType: response.headers.value('content-type') ?? '',
    );
  }

  Future<FileMetadataVm> getFileMetadata(String fileId) async {
    final trimmed = fileId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(fileId, 'fileId', 'File id is required');
    }

    final response = await _apiClient.dio.get('/files/$trimmed');
    return FileMetadataVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FileBindingVm> bindFile({
    required String fileId,
    required String ownerType,
    required String ownerId,
    required String purpose,
    bool isPrimary = false,
  }) async {
    final trimmedFileId = fileId.trim();
    if (trimmedFileId.isEmpty) {
      throw ArgumentError.value(fileId, 'fileId', 'File id is required');
    }

    final response = await _apiClient.dio.post(
      '/files/$trimmedFileId/bindings',
      data: {
        'ownerType': ownerType,
        'ownerId': ownerId,
        'purpose': purpose,
        'isPrimary': isPrimary,
      },
    );
    return FileBindingVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FileBindingVm>> listMyFileBindings({
    required String purpose,
    int limit = 100,
  }) async {
    final response = await _apiClient.dio.get(
      '/files/my-bindings',
      queryParameters: {'purpose': purpose, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['bindings'] as List<dynamic>?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FileBindingVm.fromJson)
        .toList(growable: false);
  }

  String? publicContentUrl(String fileId) {
    return resolvePublicFileContentUrl(fileId);
  }
}

class FileContentVm {
  const FileContentVm({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

class FileUploadRequestVm {
  FileUploadRequestVm({
    required this.fileId,
    required this.objectKey,
    required this.status,
    required this.method,
    required this.url,
    required this.headers,
  });

  final String fileId;
  final String objectKey;
  final String status;
  final String method;
  final String url;
  final Map<String, String> headers;

  factory FileUploadRequestVm.fromJson(Map<String, dynamic> json) {
    final upload = json['upload'] as Map<String, dynamic>? ?? const {};
    final rawHeaders = upload['headers'] as Map<String, dynamic>? ?? const {};

    return FileUploadRequestVm(
      fileId: json['fileId']?.toString() ?? '',
      objectKey: json['objectKey']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      method: upload['method']?.toString().toUpperCase() ?? 'PUT',
      url: upload['url']?.toString() ?? '',
      headers: rawHeaders.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }
}

class FileMetadataVm {
  const FileMetadataVm({
    required this.id,
    required this.originalName,
    required this.contentType,
    this.detectedContentType,
    this.extension,
    required this.sizeBytes,
  });

  final String id;
  final String originalName;
  final String contentType;
  final String? detectedContentType;
  final String? extension;
  final int sizeBytes;

  String get effectiveContentType {
    final detected = detectedContentType?.trim() ?? '';
    if (detected.isNotEmpty) return detected.toLowerCase();
    return contentType.trim().toLowerCase();
  }

  bool get isImage => effectiveContentType.startsWith('image/');
  bool get isVideo => effectiveContentType.startsWith('video/');
  bool get isAudio => effectiveContentType.startsWith('audio/');
  bool get isMedia => isImage || isVideo;

  String get extensionLabel {
    final rawExtension = extension?.trim();
    if (rawExtension != null && rawExtension.isNotEmpty) {
      return rawExtension.replaceFirst('.', '').toUpperCase();
    }

    final dot = originalName.lastIndexOf('.');
    if (dot >= 0 && dot < originalName.length - 1) {
      return originalName.substring(dot + 1).toUpperCase();
    }

    final contentTypeParts = effectiveContentType.split('/');
    final subtype = contentTypeParts.isEmpty ? '' : contentTypeParts.last;
    if (subtype.isNotEmpty && subtype != 'octet-stream') {
      return subtype.toUpperCase();
    }

    return 'FILE';
  }

  factory FileMetadataVm.fromJson(Map<String, dynamic> json) {
    return FileMetadataVm(
      id: json['id']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      detectedContentType: json['detectedContentType']?.toString(),
      extension: json['extension']?.toString(),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class FileBindingVm {
  const FileBindingVm({
    required this.id,
    required this.fileId,
    required this.ownerType,
    required this.ownerId,
    required this.purpose,
    required this.isPrimary,
    required this.createdAt,
  });

  final String id;
  final String fileId;
  final String ownerType;
  final String ownerId;
  final String purpose;
  final bool isPrimary;
  final DateTime? createdAt;

  factory FileBindingVm.fromJson(Map<String, dynamic> json) {
    return FileBindingVm(
      id: json['id']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
      ownerType: json['ownerType']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      isPrimary: json['isPrimary'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
