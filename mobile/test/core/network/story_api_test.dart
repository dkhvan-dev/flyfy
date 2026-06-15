import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/story_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test('createStory posts to dedicated story endpoint', () async {
    final adapter = _JsonAdapter({
      'id': 'circle-one',
      'caption': 'Camera moment',
      'mediaFileId': 'file-one',
      'mediaUrl': '/api/v1/public/files/file-one/content',
      'coverFileId': 'file-one',
      'coverImageUrl': '/api/v1/public/files/file-one/content',
      'mediaType': 'IMAGE',
      'stats': const {'views': 0, 'likes': 0, 'replies': 0},
      'author': {
        'userId': 'author-one',
        'locale': 'ru',
        'timezone': 'Asia/Almaty',
      },
      'seenByViewer': false,
      'shareUrl': '',
      'expiresAt': '2026-05-11T00:00:00Z',
      'createdAt': '2026-05-10T00:00:00Z',
      'updatedAt': '2026-05-10T00:00:00Z',
    });
    final api = StoryApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final circle = await api.createStory(
      CreateStoryRequest(
        caption: ' Camera moment ',
        mediaFileId: 'file-one',
        coverFileId: 'file-one',
        mediaType: StoryMediaType.image,
      ),
    );

    expect(circle.id, 'circle-one');
    expect(circle.expiresAt, DateTime.parse('2026-05-11T00:00:00Z'));
    expect(adapter.method, 'POST');
    expect(adapter.requestPath, '/api/v1/stories');
    expect(adapter.requiresAuth, isTrue);
    final body = jsonDecode(adapter.requestBody!) as Map<String, dynamic>;
    expect(body['caption'], 'Camera moment');
    expect(body['mediaFileId'], 'file-one');
    expect(body['coverFileId'], 'file-one');
    expect(body['mediaType'], 'IMAGE');
    expect(body, isNot(contains('format')));
    expect(body, isNot(contains('status')));
  });

  test('markStorySeen uses story seen endpoint', () async {
    final adapter = _JsonAdapter({'seenAt': '2026-05-10T12:30:00Z'});
    final api = StoryApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final seenAt = await api.markStorySeen('circle-one');

    expect(seenAt, DateTime.parse('2026-05-10T12:30:00Z'));
    expect(adapter.method, 'POST');
    expect(adapter.requestPath, '/api/v1/stories/circle-one/seen');
    expect(adapter.requiresAuth, isTrue);
  });

  test('listMyArchivedStories uses author archive endpoint', () async {
    final adapter = _JsonAdapter({
      'items': [
        {
          'id': 'archived-circle-one',
          'caption': 'Archived moment',
          'mediaFileId': 'file-one',
          'mediaUrl': '/api/v1/public/files/file-one/content',
          'coverFileId': 'file-one',
          'coverImageUrl': '/api/v1/public/files/file-one/content',
          'mediaType': 'IMAGE',
          'stats': const {'views': 2, 'likes': 1, 'replies': 0},
          'author': {
            'userId': 'author-one',
            'locale': 'ru',
            'timezone': 'Asia/Almaty',
          },
          'seenByViewer': true,
          'shareUrl': '',
          'expiresAt': '2026-05-11T00:00:00Z',
          'createdAt': '2026-05-10T00:00:00Z',
          'updatedAt': '2026-05-10T00:00:00Z',
        },
      ],
      'limit': 12,
      'offset': 24,
      'hasMore': false,
    });
    final api = StoryApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listMyArchivedStories(limit: 12, offset: 24);

    expect(page.items.single.id, 'archived-circle-one');
    expect(page.limit, 12);
    expect(page.offset, 24);
    expect(page.hasMore, isFalse);
    expect(adapter.method, 'GET');
    expect(adapter.requestPath, '/api/v1/stories/mine/archive');
    expect(adapter.queryParameters['limit'], '12');
    expect(adapter.queryParameters['offset'], '24');
    expect(adapter.requiresAuth, isTrue);
  });

  test('listMyActiveStories uses author active endpoint', () async {
    final adapter = _JsonAdapter({
      'items': [
        {
          'id': 'active-circle-one',
          'caption': 'Active moment',
          'mediaFileId': 'file-one',
          'mediaUrl': '/api/v1/public/files/file-one/content',
          'coverFileId': 'file-one',
          'coverImageUrl': '/api/v1/public/files/file-one/content',
          'mediaType': 'IMAGE',
          'stats': const {'views': 2, 'likes': 1, 'replies': 0},
          'author': {
            'userId': 'author-one',
            'locale': 'ru',
            'timezone': 'Asia/Almaty',
          },
          'seenByViewer': true,
          'shareUrl': '',
          'expiresAt': '2026-05-11T00:00:00Z',
          'createdAt': '2026-05-10T00:00:00Z',
          'updatedAt': '2026-05-10T00:00:00Z',
        },
      ],
      'limit': 8,
      'offset': 16,
      'hasMore': false,
    });
    final api = StoryApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listMyActiveStories(limit: 8, offset: 16);

    expect(page.items.single.id, 'active-circle-one');
    expect(page.limit, 8);
    expect(page.offset, 16);
    expect(page.hasMore, isFalse);
    expect(adapter.method, 'GET');
    expect(adapter.requestPath, '/api/v1/stories/mine/active');
    expect(adapter.queryParameters['limit'], '8');
    expect(adapter.queryParameters['offset'], '16');
    expect(adapter.requiresAuth, isTrue);
  });
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.payload);

  final Map<String, Object?> payload;
  String? method;
  String? requestPath;
  String? requestBody;
  Map<String, String> queryParameters = const {};
  bool? requiresAuth;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    requestPath = options.uri.path;
    queryParameters = options.uri.queryParameters;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    if (requestStream != null) {
      final buffer = BytesBuilder();
      await for (final chunk in requestStream) {
        buffer.add(chunk);
      }
      requestBody = utf8.decode(buffer.takeBytes());
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}
