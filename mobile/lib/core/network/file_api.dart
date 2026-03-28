import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';

class FileApi {
  FileApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<FileUploadRequestVm> createActivityMediaUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    final response = await _apiClient.dio.post(
      '/files/upload-requests',
      data: {
        'originalName': originalName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'purpose': 'ACTIVITY_MEDIA',
        'visibility': 'PROTECTED',
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
