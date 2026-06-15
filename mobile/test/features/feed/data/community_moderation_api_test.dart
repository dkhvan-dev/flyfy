import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/feed/data/community_moderation_api.dart';

void main() {
  test('listPendingPosts requests authenticated moderation queue', () async {
    final adapter = _JsonAdapter({
      'items': [_storyJson('story-1', moderationStatus: 'PENDING')],
      'limit': 20,
      'offset': 0,
      'hasMore': false,
    });
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listPendingPosts(
      communityId: ' community-1 ',
      limit: 20,
      offset: 0,
    );

    expect(
      adapter.requestPath,
      '/api/v1/communities/community-1/moderation/posts',
    );
    expect(adapter.method, 'GET');
    expect(adapter.queryParameters['limit'], '20');
    expect(adapter.queryParameters['offset'], '0');
    expect(adapter.requiresAuth, isTrue);
    expect(page.items.single.id, 'story-1');
    expect(page.items.single.moderationStatus, 'PENDING');
    expect(page.hasMore, isFalse);
  });

  test('approvePost posts review decision and parses updated story', () async {
    final adapter = _JsonAdapter(
      _storyJson('story-1', moderationStatus: 'APPROVED'),
    );
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final story = await api.approvePost(
      communityId: 'community-1',
      postId: 'story-1',
      reason: ' Полезный пост ',
    );

    expect(
      adapter.requestPath,
      '/api/v1/communities/community-1/moderation/posts/story-1/approve',
    );
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestBody, {'reason': 'Полезный пост'});
    expect(story.id, 'story-1');
    expect(story.moderationStatus, 'APPROVED');
  });

  test('rejectPost posts review decision without empty reason', () async {
    final adapter = _JsonAdapter(
      _storyJson('story-1', moderationStatus: 'REJECTED'),
    );
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final story = await api.rejectPost(
      communityId: 'community-1',
      postId: 'story-1',
      reason: '   ',
    );

    expect(
      adapter.requestPath,
      '/api/v1/communities/community-1/moderation/posts/story-1/reject',
    );
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestBody, isEmpty);
    expect(story.moderationStatus, 'REJECTED');
  });

  test('listPostDecisions requests authenticated audit history', () async {
    final adapter = _JsonAdapter({
      'items': [
        {
          'id': 'decision-1',
          'postId': 'story-1',
          'communityId': 'community-1',
          'moderatorUserId': 'moderator-1',
          'decision': 'APPROVE',
          'previousStatus': 'PENDING',
          'nextStatus': 'APPROVED',
          'postRevision': 4,
          'reason': 'Matches guidelines',
          'createdAt': '2026-06-11T10:00:00Z',
        },
      ],
      'limit': 10,
      'offset': 0,
      'hasMore': false,
    });
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listPostDecisions(
      communityId: 'community-1',
      postId: 'story-1',
      limit: 10,
      offset: 0,
    );

    expect(
      adapter.requestPath,
      '/api/v1/communities/community-1/moderation/posts/story-1/decisions',
    );
    expect(adapter.method, 'GET');
    expect(adapter.requiresAuth, isTrue);
    expect(page.items.single.id, 'decision-1');
    expect(page.items.single.decision, 'APPROVE');
    expect(page.items.single.reason, 'Matches guidelines');
    expect(page.items.single.createdAt, DateTime.utc(2026, 6, 11, 10));
  });

  test('listMembers requests authenticated community members page', () async {
    final adapter = _JsonAdapter({
      'items': [
        _memberJson(userId: 'user-1', role: 'ADMIN', nickname: 'Aigerim'),
      ],
      'limit': 20,
      'offset': 0,
      'hasMore': false,
    });
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listMembers(
      communityId: ' community-1 ',
      role: 'ADMIN',
      status: 'ACTIVE',
      limit: 99,
      offset: -2,
    );

    expect(adapter.requestPath, '/api/v1/communities/community-1/members');
    expect(adapter.method, 'GET');
    expect(adapter.queryParameters['limit'], '50');
    expect(adapter.queryParameters['offset'], '0');
    expect(adapter.queryParameters['role'], 'ADMIN');
    expect(adapter.queryParameters['status'], 'ACTIVE');
    expect(adapter.requiresAuth, isTrue);
    expect(page.items.single.userId, 'user-1');
    expect(page.items.single.role, 'ADMIN');
    expect(page.items.single.user.preferredName, 'Aigerim');
  });

  test('updateMemberRole patches authenticated member role', () async {
    final adapter = _JsonAdapter({
      'communityId': 'community-1',
      'userId': 'user-1',
      'role': 'MODERATOR',
      'status': 'ACTIVE',
      'createdAt': '2026-06-11T10:00:00Z',
      'updatedAt': '2026-06-11T11:00:00Z',
    });
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final membership = await api.updateMemberRole(
      communityId: 'community-1',
      userId: 'user-1',
      role: 'MODERATOR',
    );

    expect(
      adapter.requestPath,
      '/api/v1/communities/community-1/members/user-1/role',
    );
    expect(adapter.method, 'PATCH');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestBody, {'role': 'MODERATOR'});
    expect(membership.role, 'MODERATOR');
    expect(membership.updatedAt, DateTime.utc(2026, 6, 11, 11));
  });

  test('updateMemberStatus patches authenticated member status', () async {
    final adapter = _JsonAdapter({
      'communityId': 'community-1',
      'userId': 'user-1',
      'role': 'MEMBER',
      'status': 'BANNED',
      'createdAt': '2026-06-11T10:00:00Z',
      'updatedAt': '2026-06-11T12:00:00Z',
    });
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final membership = await api.updateMemberStatus(
      communityId: 'community-1',
      userId: 'user-1',
      status: 'BANNED',
    );

    expect(
      adapter.requestPath,
      '/api/v1/communities/community-1/members/user-1/status',
    );
    expect(adapter.method, 'PATCH');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestBody, {'status': 'BANNED'});
    expect(membership.status, 'BANNED');
    expect(membership.updatedAt, DateTime.utc(2026, 6, 11, 12));
  });

  test(
    'listMemberRoleChanges requests authenticated member audit history',
    () async {
      final adapter = _JsonAdapter({
        'items': [
          {
            'id': 'change-1',
            'communityId': 'community-1',
            'targetUserId': 'user-1',
            'actorUserId': 'admin-1',
            'actor': {
              'userId': 'admin-1',
              'nickname': 'Aigerim',
              'locale': 'en',
              'timezone': 'Asia/Almaty',
            },
            'previousRole': 'MEMBER',
            'nextRole': 'MODERATOR',
            'createdAt': '2026-06-11T12:00:00Z',
          },
        ],
        'limit': 10,
        'offset': 0,
        'hasMore': false,
      });
      final api = CommunityModerationApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.listMemberRoleChanges(
        communityId: 'community-1',
        userId: 'user-1',
        limit: 10,
        offset: 0,
      );

      expect(
        adapter.requestPath,
        '/api/v1/communities/community-1/members/user-1/role-changes',
      );
      expect(adapter.method, 'GET');
      expect(adapter.queryParameters['limit'], '10');
      expect(adapter.queryParameters['offset'], '0');
      expect(adapter.requiresAuth, isTrue);
      expect(page.items.single.id, 'change-1');
      expect(page.items.single.actor.preferredName, 'Aigerim');
      expect(page.items.single.previousRole, 'MEMBER');
      expect(page.items.single.nextRole, 'MODERATOR');
      expect(page.items.single.createdAt, DateTime.utc(2026, 6, 11, 12));
    },
  );

  test('moderation methods reject blank ids before network call', () async {
    final adapter = _JsonAdapter({'items': const []});
    final api = CommunityModerationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    expect(
      () => api.listPendingPosts(communityId: ' ', limit: 20, offset: 0),
      throwsArgumentError,
    );
    expect(adapter.requestPath, isNull);
  });
}

Map<String, Object?> _memberJson({
  required String userId,
  required String role,
  String? nickname,
}) {
  return {
    'communityId': 'community-1',
    'userId': userId,
    'role': role,
    'status': 'ACTIVE',
    'user': {
      'userId': userId,
      'nickname': nickname,
      'locale': 'en',
      'timezone': 'Asia/Almaty',
    },
    'createdAt': '2026-06-11T10:00:00Z',
    'updatedAt': '2026-06-11T10:00:00Z',
  };
}

Map<String, Object?> _storyJson(String id, {required String moderationStatus}) {
  return {
    'id': id,
    'slug': 'story-$id',
    'title': 'Story $id',
    'excerpt': 'Excerpt',
    'category': 'JOURNAL',
    'status': 'PUBLISHED',
    'moderationStatus': moderationStatus,
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
  String? method;
  Map<String, String> queryParameters = const {};
  bool? requiresAuth;
  Map<String, dynamic> requestBody = const {};

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
    requestBody = await _decodeRequestBody(requestStream);
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

Future<Map<String, dynamic>> _decodeRequestBody(
  Stream<Uint8List>? requestStream,
) async {
  if (requestStream == null) {
    return const {};
  }
  final bytes = await requestStream.fold<BytesBuilder>(
    BytesBuilder(),
    (builder, chunk) => builder..add(chunk),
  );
  if (bytes.isEmpty) {
    return const {};
  }
  final decoded = jsonDecode(utf8.decode(bytes.takeBytes()));
  if (decoded is! Map) {
    return const {};
  }
  return Map<String, dynamic>.unmodifiable({
    for (final entry in decoded.entries) entry.key.toString(): entry.value,
  });
}
