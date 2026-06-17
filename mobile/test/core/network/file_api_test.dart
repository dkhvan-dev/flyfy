import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:inflap/core/config/app_config.dart';
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

  test(
    'downloadPublicContent uses unauthenticated public file route',
    () async {
      final adapter = _FileApiAdapter();
      final api = _api(adapter);

      final content = await api.downloadPublicContent(' public-file-1 ');

      expect(adapter.captured.single.method, 'GET');
      expect(
        adapter.captured.single.path,
        '/api/v1/public/files/public-file-1/content',
      );
      expect(adapter.captured.single.requiresAuth, isFalse);
      expect(content.bytes, Uint8List.fromList([1, 2, 3]));
      expect(content.contentType, 'application/x-tgsticker');
    },
  );

  test('downloadStickerContent uses authenticated file route first', () async {
    final adapter = _FileApiAdapter();
    final api = _api(adapter);

    final content = await api.downloadStickerContent(' sticker-file-1 ');

    expect(
      adapter.captured.single.path,
      '/api/v1/files/sticker-file-1/content',
    );
    expect(adapter.captured.single.requiresAuth, isNull);
    expect(content.bytes, Uint8List.fromList([1, 2, 3]));
    expect(content.contentType, 'application/x-tgsticker');
  });

  test('downloadStickerContent falls back to public file route', () async {
    final adapter = _FileApiAdapter(failAuthenticatedContent: true);
    final api = _api(adapter);

    final content = await api.downloadStickerContent(' sticker-file-1 ');

    expect(adapter.captured.map((request) => request.path), [
      '/api/v1/files/sticker-file-1/content',
      '/api/v1/public/files/sticker-file-1/content',
    ]);
    expect(adapter.captured.first.requiresAuth, isNull);
    expect(adapter.captured.last.requiresAuth, isFalse);
    expect(content.bytes, Uint8List.fromList([1, 2, 3]));
    expect(content.contentType, 'application/x-tgsticker');
  });

  test('resolves public file content urls from backend story responses', () {
    expect(
      resolvePublicFileContentUrlFromResponse(
        contentUrl: '/api/v1/public/files/cover-1/content',
      ),
      '${Uri.parse(AppConfig.apiBaseUrl).origin}/api/v1/public/files/cover-1/content',
    );
    expect(
      resolvePublicFileContentUrlFromResponse(
        contentUrl: 'https://cdn.example.test/cover.jpg',
      ),
      'https://cdn.example.test/cover.jpg',
    );
    expect(
      resolvePublicFileContentUrlFromResponse(fileId: 'cover-2'),
      '${AppConfig.apiBaseUrl}/public/files/cover-2/content',
    );
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
    this.requiresAuth,
  });

  final String method;
  final String path;
  final Map<String, dynamic> body;
  final bool? requiresAuth;
}

class _FileApiAdapter implements HttpClientAdapter {
  _FileApiAdapter({this.failAuthenticatedContent = false});

  final bool failAuthenticatedContent;
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
        requiresAuth: options.extra['requiresAuth'] as bool?,
      ),
    );

    if (options.uri.path.endsWith('/release')) {
      return ResponseBody.fromString('', 204);
    }
    if (options.uri.path.endsWith('/content')) {
      if (failAuthenticatedContent &&
          !options.uri.path.contains('/public/files/')) {
        return ResponseBody.fromString('', 403);
      }
      return ResponseBody.fromBytes(
        [1, 2, 3],
        200,
        headers: {
          Headers.contentTypeHeader: ['application/x-tgsticker'],
        },
      );
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
