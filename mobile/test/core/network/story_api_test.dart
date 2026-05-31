import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/story_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test('listStoriesPage exposes backend total when it is present', () async {
    final adapter = _JsonAdapter({
      'items': [_storyJson('one'), _storyJson('two')],
      'total': 42,
    });
    final api = StoryApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listStoriesPage(limit: 1);

    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
    expect(page.total, 42);
  });

  test(
    'listStoriesPage falls back to parsed item count without total',
    () async {
      final adapter = _JsonAdapter({
        'items': [_storyJson('one')],
      });
      final api = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.listStoriesPage(limit: 8);

      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
      expect(page.total, 1);
    },
  );

  test(
    'countPublishedStoriesForUser reads public author count endpoint',
    () async {
      final adapter = _JsonAdapter({'userId': 'user-1', 'publishedStories': 7});
      final api = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final count = await api.countPublishedStoriesForUser('user-1');

      expect(count, 7);
      expect(
        adapter.requestPath,
        '/api/v1/stories/users/user-1/published-count',
      );
      expect(adapter.requiresAuth, isFalse);
    },
  );

  test('getUserPopularStories filters author stories by views', () async {
    final adapter = _JsonAdapter({
      'items': [_storyJson('one')],
      'total': 1,
    });
    final api = StoryApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final stories = await api.getUserPopularStories(' user-1 ', limit: 3);

    expect(stories.single.id, 'one');
    expect(adapter.requestPath, '/api/v1/stories');
    expect(adapter.queryParameters['authorId'], 'user-1');
    expect(adapter.queryParameters['sort'], 'popular_desc');
    expect(adapter.queryParameters['limit'], '4');
    expect(adapter.queryParameters['offset'], '0');
  });

  test(
    'listStoriesPage sends country and city filters as first-class query params',
    () async {
      final adapter = _JsonAdapter({
        'items': [_storyJson('one')],
        'total': 1,
      });
      final api = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.listStoriesPage(countryCode: ' kz ', cityId: ' almaty ');

      expect(adapter.requestPath, '/api/v1/stories');
      expect(adapter.queryParameters['countryCode'], 'KZ');
      expect(adapter.queryParameters['cityId'], 'almaty');
      expect(adapter.queryParameters, isNot(containsPair('place', 'KZ')));
    },
  );
}

Map<String, Object?> _storyJson(String id) {
  return {
    'id': id,
    'slug': 'story-$id',
    'title': 'Story $id',
    'excerpt': 'Excerpt',
    'category': 'JOURNAL',
    'status': 'PUBLISHED',
    'tags': const <String>[],
    'stats': const <String, int>{},
    'author': {
      'userId': 'author-$id',
      'locale': 'en',
      'timezone': 'Asia/Almaty',
    },
    'likedByViewer': false,
    'shareUrl': '',
    'createdAt': '2026-05-10T00:00:00Z',
    'updatedAt': '2026-05-10T00:00:00Z',
  };
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.payload);

  final Map<String, Object?> payload;
  String? requestPath;
  Map<String, String> queryParameters = const {};
  bool? requiresAuth;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
    queryParameters = options.uri.queryParameters;
    requiresAuth = options.extra['requiresAuth'] as bool?;
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
