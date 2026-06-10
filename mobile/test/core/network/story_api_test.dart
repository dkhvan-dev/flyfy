import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/story_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test('listStoriesPage exposes backend pagination metadata', () async {
    final adapter = _JsonAdapter({
      'items': [_storyJson('one'), _storyJson('two')],
      'total': 42,
      'limit': 2,
      'offset': 6,
      'hasMore': true,
    });
    final api = StoryApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listStoriesPage(limit: 2, offset: 6);

    expect(page.items, hasLength(2));
    expect(page.hasMore, isTrue);
    expect(page.total, 42);
    expect(page.limit, 2);
    expect(page.offset, 6);
    expect(adapter.queryParameters['limit'], '2');
    expect(adapter.queryParameters['offset'], '6');
    expect(adapter.requiresAuth, isFalse);
  });

  test(
    'public story reads and share work without a guest access token',
    () async {
      final listAdapter = _JsonAdapter({'items': const [], 'total': 0});
      final listApi = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = listAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      await listApi.listStoriesPage();

      expect(listAdapter.requestPath, '/api/v1/stories');
      expect(listAdapter.requiresAuth, isFalse);

      final detailAdapter = _JsonAdapter({'story': _storyJson('one')});
      final detailApi = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = detailAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      await detailApi.getPublicStoryBySlug('story-one');

      expect(detailAdapter.requestPath, '/api/v1/public/stories/story-one');
      expect(detailAdapter.requiresAuth, isFalse);

      final commentsAdapter = _JsonAdapter({
        'items': [_commentJson('comment-one')],
      });
      final commentsApi = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = commentsAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      await commentsApi.listComments('story-one');

      expect(commentsAdapter.requestPath, '/api/v1/stories/story-one/comments');
      expect(commentsAdapter.requiresAuth, isFalse);

      final shareAdapter = _JsonAdapter({
        'shareUrl': 'https://inflap.app/stories/story-one',
        'shares': 2,
      });
      final shareApi = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = shareAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      final share = await shareApi.shareStory('story-one');

      expect(share.$2, 2);
      expect(shareAdapter.requestPath, '/api/v1/stories/story-one/share');
      expect(shareAdapter.requiresAuth, isFalse);
    },
  );

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
    'listStoriesPage uses offset lower bound when old response omits total',
    () async {
      final adapter = _JsonAdapter({
        'items': [_storyJson('one'), _storyJson('two')],
      });
      final api = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.listStoriesPage(limit: 8, offset: 20);

      expect(page.items, hasLength(2));
      expect(page.hasMore, isFalse);
      expect(page.total, 22);
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
    expect(adapter.queryParameters['limit'], '3');
    expect(adapter.queryParameters['offset'], '0');
  });

  test(
    'listMyStoriesPage sends status and parses pagination metadata',
    () async {
      final adapter = _JsonAdapter({
        'items': [_storyJson('draft')],
        'total': 9,
        'limit': 5,
        'offset': 10,
        'hasMore': true,
      });
      final api = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.listMyStoriesPage(
        status: ' draft ',
        limit: 5,
        offset: 10,
      );

      expect(adapter.requestPath, '/api/v1/stories/mine');
      expect(adapter.queryParameters['status'], 'DRAFT');
      expect(page.total, 9);
      expect(page.limit, 5);
      expect(page.offset, 10);
      expect(page.hasMore, isTrue);
    },
  );

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

  test(
    'story list endpoints send material format filters separately',
    () async {
      final publicAdapter = _JsonAdapter({
        'items': [_storyJson('one')],
        'total': 1,
      });
      final publicApi = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = publicAdapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await publicApi.listStoriesPage(
        formats: const [' story ', 'GUIDE'],
        categories: const ['JOURNAL'],
      );

      expect(publicAdapter.requestPath, '/api/v1/stories');
      expect(publicAdapter.queryParameters['format'], 'story,GUIDE');
      expect(publicAdapter.queryParameters['category'], 'JOURNAL');

      final mineAdapter = _JsonAdapter({
        'items': [_storyJson('draft')],
        'total': 1,
      });
      final mineApi = StoryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = mineAdapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await mineApi.listMyStoriesPage(formats: const ['ARTICLE']);

      expect(mineAdapter.requestPath, '/api/v1/stories/mine');
      expect(mineAdapter.queryParameters['format'], 'ARTICLE');
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

Map<String, Object?> _commentJson(String id) {
  return {
    'id': id,
    'storyId': 'story-one',
    'body': 'Comment $id',
    'likes': 0,
    'likedByMe': false,
    'shareUrl': '',
    'author': {
      'userId': 'author-$id',
      'locale': 'en',
      'timezone': 'Asia/Almaty',
    },
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

class _EmptySecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => null;

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
