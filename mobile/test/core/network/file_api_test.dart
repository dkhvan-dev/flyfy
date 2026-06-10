import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/file_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test('story uploads use story media purpose', () async {
    final adapter = _FileApiAdapter();
    final api = _api(adapter);

    await api.createStoryCoverUpload(
      originalName: 'cover.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    );
    await api.createStoryInlineImageUpload(
      originalName: 'inline.webp',
      contentType: 'image/webp',
      sizeBytes: 2048,
    );

    expect(adapter.captured.map((request) => request.body['purpose']), [
      'STORY_MEDIA',
      'STORY_MEDIA',
    ]);
    expect(adapter.captured.map((request) => request.body['visibility']), [
      'PUBLIC',
      'PUBLIC',
    ]);
  });

  test('releaseUnboundUpload calls dedicated release endpoint', () async {
    final adapter = _FileApiAdapter();
    final api = _api(adapter);

    await api.releaseUnboundUpload(' file-1 ');

    expect(adapter.captured.single.method, 'POST');
    expect(adapter.captured.single.path, '/api/v1/files/file-1/release');
  });
}

FileApi _api(_FileApiAdapter adapter) {
  return FileApi(
    apiClient: ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _FakeSecureStorage(),
    ),
  );
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _CapturedFileRequest {
  const _CapturedFileRequest({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> body;
}

class _FileApiAdapter implements HttpClientAdapter {
  final captured = <_CapturedFileRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(
      _CapturedFileRequest(
        method: options.method,
        path: options.uri.path,
        body: await _decodeBody(requestStream),
      ),
    );

    if (options.uri.path.endsWith('/release')) {
      return ResponseBody.fromString('', 204);
    }

    return ResponseBody.fromString(
      jsonEncode({
        'fileId': 'file-${captured.length}',
        'objectKey': 'story_media/2026/06/09/file-${captured.length}.jpg',
        'status': 'PENDING_UPLOAD',
        'upload': {
          'method': 'PUT',
          'url': 'https://storage.test/upload',
          'headers': {'Content-Type': 'image/jpeg'},
          'expiresAt': '2026-06-09T10:00:00Z',
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Future<Map<String, dynamic>> _decodeBody(
    Stream<Uint8List>? requestStream,
  ) async {
    if (requestStream == null) {
      return const {};
    }
    final builder = BytesBuilder();
    await for (final chunk in requestStream) {
      builder.add(chunk);
    }
    final bodyText = utf8.decode(builder.takeBytes());
    if (bodyText.trim().isEmpty) {
      return const {};
    }
    return jsonDecode(bodyText) as Map<String, dynamic>;
  }

  @override
  void close({bool force = false}) {}
}
