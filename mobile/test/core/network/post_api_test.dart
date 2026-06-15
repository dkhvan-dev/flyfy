import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/post_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test('listPostsPage exposes backend pagination metadata', () async {
    final adapter = _JsonAdapter({
      'items': [_postJson('one'), _postJson('two')],
      'total': 42,
      'limit': 2,
      'offset': 6,
      'hasMore': true,
    });
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listPostsPage(limit: 2, offset: 6);

    expect(page.items, hasLength(2));
    expect(page.hasMore, isTrue);
    expect(page.total, 42);
    expect(page.limit, 2);
    expect(page.offset, 6);
    expect(adapter.queryParameters['limit'], '2');
    expect(adapter.queryParameters['offset'], '6');
    expect(adapter.requiresAuth, isNull);
    expect(adapter.optionalAuth, isTrue);
  });

  test('listPostsPage parses post ownership edit flag', () async {
    final adapter = _JsonAdapter({
      'items': [_postJson('one', editable: true)],
      'total': 1,
    });
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listPostsPage(limit: 1);

    expect(page.items.single.editable, isTrue);
  });

  test('listPostsPage filters community posts with optional auth', () async {
    final adapter = _JsonAdapter({
      'items': [_postJson('community-one', communityId: 'community-1')],
      'total': 1,
    });
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listPostsPage(
      communityId: ' community-1 ',
      sort: 'newest',
      limit: 6,
    );

    expect(page.items.single.communityId, 'community-1');
    expect(adapter.requestPath, '/api/v1/posts');
    expect(adapter.queryParameters['communityId'], 'community-1');
    expect(adapter.queryParameters['sort'], 'newest');
    expect(adapter.queryParameters['limit'], '6');
    expect(adapter.requiresAuth, isNull);
    expect(adapter.optionalAuth, isTrue);
  });

  test(
    'public post reads and share work without a guest access token',
    () async {
      final listAdapter = _JsonAdapter({'items': const [], 'total': 0});
      final listApi = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = listAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      await listApi.listPostsPage();

      expect(listAdapter.requestPath, '/api/v1/posts');
      expect(listAdapter.requiresAuth, isNull);
      expect(listAdapter.optionalAuth, isTrue);

      final detailAdapter = _JsonAdapter({'post': _postJson('one')});
      final detailApi = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = detailAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      await detailApi.getPublicPostBySlug('post-one');

      expect(detailAdapter.requestPath, '/api/v1/public/posts/post-one');
      expect(detailAdapter.requiresAuth, isNull);
      expect(detailAdapter.optionalAuth, isTrue);

      final commentsAdapter = _JsonAdapter({
        'items': [_commentJson('comment-one')],
      });
      final commentsApi = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = commentsAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      await commentsApi.listComments('post-one');

      expect(commentsAdapter.requestPath, '/api/v1/posts/post-one/comments');
      expect(commentsAdapter.requiresAuth, isNull);
      expect(commentsAdapter.optionalAuth, isTrue);

      final shareAdapter = _JsonAdapter({
        'shareUrl': 'https://inflap.app/posts/post-one',
        'shares': 2,
      });
      final shareApi = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = shareAdapter,
          secureStorage: _EmptySecureStorage(),
        ),
      );

      final share = await shareApi.sharePost('post-one');

      expect(share.$2, 2);
      expect(shareAdapter.requestPath, '/api/v1/posts/post-one/share');
      expect(shareAdapter.requiresAuth, isFalse);
    },
  );

  test('listPostsPage falls back to parsed item count without total', () async {
    final adapter = _JsonAdapter({
      'items': [_postJson('one')],
    });
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listPostsPage(limit: 8);

    expect(page.items, hasLength(1));
    expect(page.hasMore, isFalse);
    expect(page.total, 1);
  });

  test(
    'listPostsPage uses offset lower bound when old response omits total',
    () async {
      final adapter = _JsonAdapter({
        'items': [_postJson('one'), _postJson('two')],
      });
      final api = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.listPostsPage(limit: 8, offset: 20);

      expect(page.items, hasLength(2));
      expect(page.hasMore, isFalse);
      expect(page.total, 22);
    },
  );

  test(
    'countPublishedPostsForUser reads public author count endpoint',
    () async {
      final adapter = _JsonAdapter({'userId': 'user-1', 'publishedPosts': 7});
      final api = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final count = await api.countPublishedPostsForUser('user-1');

      expect(count, 7);
      expect(adapter.requestPath, '/api/v1/posts/users/user-1/published-count');
      expect(adapter.requiresAuth, isFalse);
    },
  );

  test('getUserPopularPosts filters author posts by views', () async {
    final adapter = _JsonAdapter({
      'items': [_postJson('one')],
      'total': 1,
    });
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final posts = await api.getUserPopularPosts(' user-1 ', limit: 3);

    expect(posts.single.id, 'one');
    expect(adapter.requestPath, '/api/v1/posts');
    expect(adapter.queryParameters['authorId'], 'user-1');
    expect(adapter.queryParameters['sort'], 'popular_desc');
    expect(adapter.queryParameters['limit'], '3');
    expect(adapter.queryParameters['offset'], '0');
  });

  test(
    'listMyPostsPage sends status, community and moderation filters',
    () async {
      final adapter = _JsonAdapter({
        'items': [_postJson('draft')],
        'total': 9,
        'limit': 5,
        'offset': 10,
        'hasMore': true,
      });
      final api = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.listMyPostsPage(
        status: ' draft ',
        communityId: ' community-1 ',
        moderationStatuses: const [' pending ', 'APPROVED'],
        limit: 5,
        offset: 10,
      );

      expect(adapter.requestPath, '/api/v1/posts/mine');
      expect(adapter.queryParameters['status'], 'DRAFT');
      expect(adapter.queryParameters['communityId'], 'community-1');
      expect(adapter.queryParameters['moderationStatus'], 'pending,APPROVED');
      expect(page.total, 9);
      expect(page.limit, 5);
      expect(page.offset, 10);
      expect(page.hasMore, isTrue);
    },
  );

  test(
    'listPostsPage sends country and city filters as first-class query params',
    () async {
      final adapter = _JsonAdapter({
        'items': [_postJson('one')],
        'total': 1,
      });
      final api = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.listPostsPage(countryCode: ' kz ', cityId: ' almaty ');

      expect(adapter.requestPath, '/api/v1/posts');
      expect(adapter.queryParameters['countryCode'], 'KZ');
      expect(adapter.queryParameters['cityId'], 'almaty');
      expect(adapter.queryParameters, isNot(containsPair('place', 'KZ')));
    },
  );

  test('post list endpoints send material format filters separately', () async {
    final publicAdapter = _JsonAdapter({
      'items': [_postJson('one')],
      'total': 1,
    });
    final publicApi = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = publicAdapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    await publicApi.listPostsPage(
      formats: const [' article ', 'GUIDE'],
      categories: const ['JOURNAL'],
    );

    expect(publicAdapter.requestPath, '/api/v1/posts');
    expect(publicAdapter.queryParameters['format'], 'article,GUIDE');
    expect(publicAdapter.queryParameters['category'], 'JOURNAL');

    final mineAdapter = _JsonAdapter({
      'items': [_postJson('draft')],
      'total': 1,
    });
    final mineApi = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = mineAdapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    await mineApi.listMyPostsPage(formats: const ['ARTICLE']);

    expect(mineAdapter.requestPath, '/api/v1/posts/mine');
    expect(mineAdapter.queryParameters['format'], 'ARTICLE');
  });

  test('checkCreateEligibility parses rate-limit preflight response', () async {
    final adapter = _JsonAdapter({
      'canCreate': false,
      'limit': 10,
      'remaining': 0,
      'windowSeconds': 3600,
      'retryAfterSeconds': 1080,
      'nextAvailableAt': '2026-06-14T12:18:00Z',
    });
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final eligibility = await api.checkCreateEligibility();

    expect(adapter.method, 'GET');
    expect(adapter.requestPath, '/api/v1/posts/create-eligibility');
    expect(adapter.requiresAuth, isTrue);
    expect(eligibility.canCreate, isFalse);
    expect(eligibility.limit, 10);
    expect(eligibility.remaining, 0);
    expect(eligibility.window, const Duration(hours: 1));
    expect(eligibility.retryAfter, const Duration(minutes: 18));
    expect(eligibility.nextAvailableAt, DateTime.parse('2026-06-14T12:18:00Z'));
  });

  test('posts parse expiry and viewer seen metadata', () async {
    final adapter = _JsonAdapter({
      'items': [
        _postJson(
          'seen',
          expiresAt: '2026-05-11T00:00:00Z',
          seenByViewer: true,
          seenAt: '2026-05-10T12:30:00Z',
        ),
      ],
      'total': 1,
    });
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listPostsPage();
    final post = page.items.single;

    expect(post.expiresAt, DateTime.parse('2026-05-11T00:00:00Z'));
    expect(post.seenByViewer, isTrue);
    expect(post.seenAt, DateTime.parse('2026-05-10T12:30:00Z'));
  });

  test('markPostSeen posts auth-only marker and parses seenAt', () async {
    final adapter = _JsonAdapter({'seenAt': '2026-05-10T12:30:00Z'});
    final api = PostApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final seenAt = await api.markPostSeen('post-one');

    expect(seenAt, DateTime.parse('2026-05-10T12:30:00Z'));
    expect(adapter.method, 'POST');
    expect(adapter.requestPath, '/api/v1/posts/post-one/seen');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.optionalAuth, isNull);
  });

  test(
    'reportPost submits auth-only report and parses moderation outcome',
    () async {
      final adapter = _JsonAdapter({
        'report': {
          'id': 'report-1',
          'postId': 'post-one',
          'reason': 'SPAM',
          'status': 'OPEN',
          'createdAt': '2026-05-10T00:00:00Z',
          'updatedAt': '2026-05-10T00:00:00Z',
        },
        'post': _postJson('one'),
        'openReportsCount': '3',
        'autoHidden': true,
      }, statusCode: 201);
      final api = PostApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final result = await api.reportPost(
        'post-one',
        reason: ' spam ',
        details: ' copied listing ',
      );

      expect(adapter.method, 'POST');
      expect(adapter.requestPath, '/api/v1/posts/post-one/report');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.optionalAuth, isNull);
      expect(jsonDecode(adapter.requestBody!), {
        'reason': 'SPAM',
        'details': 'copied listing',
      });
      expect(result.reportId, 'report-1');
      expect(result.reportStatus, 'OPEN');
      expect(result.openReportsCount, 3);
      expect(result.autoHidden, isTrue);
      expect(result.post?.id, 'one');
    },
  );
}

Map<String, Object?> _postJson(
  String id, {
  String? communityId,
  String? expiresAt,
  bool seenByViewer = false,
  String? seenAt,
  bool editable = false,
}) {
  return {
    'id': id,
    'slug': 'post-$id',
    'title': 'Post $id',
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
    'editable': editable,
    'seenByViewer': seenByViewer,
    'seenAt': ?seenAt,
    'shareUrl': '',
    'communityId': ?communityId,
    'expiresAt': ?expiresAt,
    'createdAt': '2026-05-10T00:00:00Z',
    'updatedAt': '2026-05-10T00:00:00Z',
  };
}

Map<String, Object?> _commentJson(String id) {
  return {
    'id': id,
    'postId': 'post-one',
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
  _JsonAdapter(this.payload, {this.statusCode = 200});

  final Map<String, Object?> payload;
  final int statusCode;
  String? method;
  String? requestPath;
  String? requestBody;
  Map<String, String> queryParameters = const {};
  bool? requiresAuth;
  bool? optionalAuth;

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
    optionalAuth = options.extra['optionalAuth'] as bool?;
    if (requestStream != null) {
      final buffer = BytesBuilder();
      await for (final chunk in requestStream) {
        buffer.add(chunk);
      }
      requestBody = utf8.decode(buffer.takeBytes());
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
