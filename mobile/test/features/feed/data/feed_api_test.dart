import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';

void main() {
  test(
    'FeedEventTypes exposes backend wire names for required quality signals',
    () {
      expect(FeedEventTypes.impression, 'impression');
      expect(FeedEventTypes.click, 'click');
      expect(FeedEventTypes.dwell, 'dwell');
      expect(FeedEventTypes.like, 'like');
      expect(FeedEventTypes.comment, 'comment');
      expect(FeedEventTypes.share, 'share');
      expect(FeedEventTypes.subscribe, 'subscribe');
      expect(FeedEventTypes.hide, 'hide');
      expect(FeedEventTypes.notInterested, 'not_interested');
      expect(FeedEventTypes.report, 'report');
      expect(FeedEventTypes.requiredQualitySignals, {
        'impression',
        'click',
        'dwell',
        'like',
        'comment',
        'share',
        'subscribe',
        'hide',
        'not_interested',
        'report',
      });
    },
  );

  test('getFeed sends feed query params and parses page blocks', () async {
    final adapter = _JsonAdapter({
      'nextCursor': 'cursor-2',
      'assignment': {'rankingExperiment': 'rank-v2'},
      'items': [
        {
          'id': 'tray-1',
          'type': 'stories_tray',
          'data': {
            'stories': [_storyJson('one')],
          },
        },
      ],
    });
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.getFeed(
      surface: ' home ',
      tab: ' for_you ',
      cursor: ' cursor-1 ',
      limit: 30,
    );

    expect(adapter.requestPath, '/api/v1/feed');
    expect(adapter.queryParameters['surface'], 'home');
    expect(adapter.queryParameters['tab'], 'for_you');
    expect(adapter.queryParameters['cursor'], 'cursor-1');
    expect(adapter.queryParameters['limit'], '30');
    expect(adapter.requiresAuth, isNull);
    expect(adapter.optionalAuth, isTrue);
    expect(page.nextCursor, 'cursor-2');
    expect(page.assignment.rankingExperiment, 'rank-v2');
    expect(page.items.single.type, FeedBlockType.storiesTray);
    expect(page.items.single.stories.single.id, 'one');
  });

  test('getFeed is public and does not require a guest access token', () async {
    final adapter = _JsonAdapter({'nextCursor': null, 'items': const []});
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _EmptySecureStorage(),
      ),
    );

    final page = await api.getFeed();

    expect(page.items, isEmpty);
    expect(adapter.requestPath, '/api/v1/feed');
    expect(adapter.requiresAuth, isNull);
    expect(adapter.optionalAuth, isTrue);
  });

  test('getFeed sends location context for community suggestions', () async {
    final adapter = _JsonAdapter({'items': const []});
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _EmptySecureStorage(),
      ),
    );

    await api.getFeed(countryCode: ' vn ', cityId: ' da-nang ');

    expect(adapter.method, 'GET');
    expect(adapter.requestPath, '/api/v1/feed');
    expect(adapter.queryParameters['countryCode'], 'vn');
    expect(adapter.queryParameters['cityId'], 'da-nang');
    expect(adapter.optionalAuth, isTrue);
  });

  test('getFeed clamps limit lower bound to one', () async {
    final adapter = _JsonAdapter({'items': const []});
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    await api.getFeed(limit: 0);

    expect(adapter.queryParameters['limit'], '1');
  });

  test('FeedCommunityVm parses viewer moderation capability', () {
    final community = FeedCommunityVm.fromJson({
      'id': 'community-1',
      'title': 'Investments',
      'description': 'Market news and practical investing guides.',
      'topic': 'FINANCE',
      'postingPolicy': 'MEMBERS_AFTER_MODERATION',
      'postCount': 82,
      'viewerRole': 'MODERATOR',
      'viewerCanModerate': true,
    });

    expect(community.viewerRole, 'MODERATOR');
    expect(community.viewerCanModerate, isTrue);
    expect(
      community.description,
      'Market news and practical investing guides.',
    );
    expect(community.topic, 'FINANCE');
    expect(community.postingPolicy, 'MEMBERS_AFTER_MODERATION');
    expect(community.postCount, 82);
  });

  test('listCommunities requests public community discovery page', () async {
    final adapter = _JsonAdapter({
      'items': [
        {
          'id': 'community-1',
          'title': 'Investments',
          'description': 'Practical investing guides.',
          'topic': 'FINANCE',
          'followerCount': 6326,
          'postCount': 82,
          'followedByViewer': true,
        },
      ],
      'limit': 30,
      'offset': 5,
    });
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _EmptySecureStorage(),
      ),
    );

    final page = await api.listCommunities(
      topic: ' finance ',
      countryCode: ' kz ',
      cityId: ' city-1 ',
      limit: 30,
      offset: 5,
    );

    expect(adapter.method, 'GET');
    expect(adapter.requestPath, '/api/v1/communities');
    expect(adapter.queryParameters['topic'], 'finance');
    expect(adapter.queryParameters['countryCode'], 'kz');
    expect(adapter.queryParameters['cityId'], 'city-1');
    expect(adapter.queryParameters['limit'], '30');
    expect(adapter.queryParameters['offset'], '5');
    expect(adapter.requiresAuth, isNull);
    expect(adapter.optionalAuth, isTrue);
    expect(page.items.single.id, 'community-1');
    expect(page.items.single.title, 'Investments');
    expect(page.items.single.followedByViewer, isTrue);
    expect(page.limit, 30);
    expect(page.offset, 5);
    expect(page.hasMore, isFalse);
  });

  test('listCommunities can request only followed communities', () async {
    final adapter = _JsonAdapter({
      'items': [
        {
          'id': 'community-1',
          'title': 'Investments',
          'followerCount': 6326,
          'followedByViewer': true,
        },
      ],
    });
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.listCommunities(onlyFollowed: true, limit: 12);

    expect(adapter.requestPath, '/api/v1/communities');
    expect(adapter.queryParameters['onlyFollowed'], 'true');
    expect(adapter.queryParameters.containsKey('excludeFollowed'), isFalse);
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.optionalAuth, isNull);
    expect(page.items.single.followedByViewer, isTrue);
  });

  test('getCommunity requests public community profile by id', () async {
    final adapter = _JsonAdapter({
      'id': 'community-1',
      'title': 'Investments',
      'description': 'Practical investing guides.',
      'postingPolicy': 'MEMBERS_AFTER_MODERATION',
      'followerCount': 6326,
      'postCount': 82,
      'followedByViewer': true,
    });
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _EmptySecureStorage(),
      ),
    );

    final community = await api.getCommunity(' community-1 ');

    expect(adapter.method, 'GET');
    expect(adapter.requestPath, '/api/v1/communities/community-1');
    expect(adapter.requiresAuth, isNull);
    expect(adapter.optionalAuth, isTrue);
    expect(community.id, 'community-1');
    expect(community.description, 'Practical investing guides.');
    expect(community.membersCount, 6326);
    expect(community.postCount, 82);
    expect(community.followedByViewer, isTrue);
  });

  test('followCommunity posts authenticated follow action', () async {
    final adapter = _JsonAdapter({
      'id': 'community-1',
      'title': 'Almaty weekends',
      'followerCount': 43,
      'followedByViewer': true,
    });
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final community = await api.followCommunity(' community-1 ');

    expect(adapter.method, 'POST');
    expect(adapter.requestPath, '/api/v1/communities/community-1/follow');
    expect(adapter.requiresAuth, isTrue);
    expect(community.id, 'community-1');
    expect(community.followedByViewer, isTrue);
    expect(community.membersCount, 43);
  });

  test('unfollowCommunity deletes authenticated follow action', () async {
    final adapter = _JsonAdapter({
      'id': 'community-1',
      'title': 'Almaty weekends',
      'followerCount': 42,
      'followedByViewer': false,
    });
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final community = await api.unfollowCommunity('community-1');

    expect(adapter.method, 'DELETE');
    expect(adapter.requestPath, '/api/v1/communities/community-1/follow');
    expect(adapter.requiresAuth, isTrue);
    expect(community.followedByViewer, isFalse);
    expect(community.membersCount, 42);
  });

  test('trackFeedEvents posts optional-auth event batch', () async {
    final adapter = _JsonAdapter({'accepted': 1});
    final api = FeedApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final accepted = await api.trackFeedEvents([
      FeedEventRequest(
        eventId: 'event-1',
        eventType: ' not_interested ',
        surface: ' content ',
        tab: ' for_you ',
        blockId: ' post:post-1 ',
        blockType: 'post_card',
        postId: ' post-1 ',
        rank: 2,
        requestId: ' req-1 ',
        metadata: const {'source': 'overflow_menu'},
      ),
    ]);

    expect(accepted, 1);
    expect(adapter.method, 'POST');
    expect(adapter.requestPath, '/api/v1/feed/events');
    expect(adapter.requiresAuth, isNull);
    expect(adapter.optionalAuth, isTrue);
    final events = adapter.jsonBody?['events'] as List<Object?>?;
    expect(events, hasLength(1));
    final event = events!.single as Map<String, Object?>;
    expect(event['eventId'], 'event-1');
    expect(event['type'], 'not_interested');
    expect(event.containsKey('eventType'), isFalse);
    expect(event['surface'], 'content');
    expect(event['tab'], 'for_you');
    expect(event['blockId'], 'post:post-1');
    expect(event['blockType'], 'post_card');
    expect(event['postId'], 'post-1');
    expect(event['rank'], 2);
    expect(event['requestId'], 'req-1');
    expect(event['metadata'], {'source': 'overflow_menu'});
  });

  test(
    'trackFeedEvents adds last feed ranking experiment assignment',
    () async {
      final adapter = _JsonAdapter({
        'assignment': {'rankingExperiment': 'rank-v2'},
        'items': const [],
        'accepted': 1,
      });
      final api = FeedApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.getFeed(surface: 'content', tab: 'for_you');
      await api.trackFeedEvents([
        const FeedEventRequest(
          eventId: 'event-1',
          eventType: 'impression',
          surface: 'content',
          tab: 'for_you',
          blockId: 'post:post-1',
          blockType: 'post_card',
          postId: 'post-1',
          rank: 1,
          metadata: {'source': 'post_card'},
        ),
      ]);

      final events = adapter.jsonBody?['events'] as List<Object?>?;
      final event = events!.single as Map<String, Object?>;
      expect(event['metadata'], {
        'source': 'post_card',
        'rankingExperiment': 'rank-v2',
      });
    },
  );

  test(
    'trackFeedEvents retries failed batches with original ranking metadata',
    () async {
      final adapter = _SequenceAdapter([
        _SequenceResponse.json({
          'assignment': {'rankingExperiment': 'rank-v2'},
          'items': const [],
        }),
        _SequenceResponse.failure(statusCode: 503),
        _SequenceResponse.json({
          'assignment': {'rankingExperiment': 'rank-v3'},
          'items': const [],
        }),
        _SequenceResponse.json({'accepted': 2}),
      ]);
      final api = FeedApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.getFeed(surface: 'content', tab: 'for_you');
      await expectLater(
        api.trackFeedEvents([
          const FeedEventRequest(
            eventId: 'event-rank-v2',
            eventType: 'impression',
            surface: 'content',
            tab: 'for_you',
            blockId: 'post:one',
            blockType: 'post_card',
            postId: 'one',
            rank: 1,
          ),
        ]),
        throwsA(isA<DioException>()),
      );
      await api.getFeed(surface: 'content', tab: 'for_you');

      final accepted = await api.trackFeedEvents([
        const FeedEventRequest(
          eventId: 'event-rank-v3',
          eventType: 'click',
          surface: 'content',
          tab: 'for_you',
          blockId: 'post:two',
          blockType: 'post_card',
          postId: 'two',
          rank: 2,
        ),
      ]);

      expect(accepted, 2);
      final body = adapter.jsonBodies.last;
      final events = body['events'] as List<Object?>;
      expect(events, hasLength(2));
      final first = events[0] as Map<String, Object?>;
      final second = events[1] as Map<String, Object?>;
      expect(first['eventId'], 'event-rank-v2');
      expect(first['metadata'], containsPair('rankingExperiment', 'rank-v2'));
      expect(second['eventId'], 'event-rank-v3');
      expect(second['metadata'], containsPair('rankingExperiment', 'rank-v3'));
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
  String? method;
  Map<String, String> queryParameters = const {};
  Map<String, Object?>? jsonBody;
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
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = chunks.expand((chunk) => chunk).toList(growable: false);
      if (bytes.isNotEmpty) {
        jsonBody = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      }
    }
    requiresAuth = options.extra['requiresAuth'] as bool?;
    optionalAuth = options.extra['optionalAuth'] as bool?;
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

class _SequenceResponse {
  const _SequenceResponse._({this.payload, this.statusCode});

  factory _SequenceResponse.json(Map<String, Object?> payload) {
    return _SequenceResponse._(payload: payload);
  }

  factory _SequenceResponse.failure({required int statusCode}) {
    return _SequenceResponse._(statusCode: statusCode);
  }

  final Map<String, Object?>? payload;
  final int? statusCode;
}

class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this.responses);

  final List<_SequenceResponse> responses;
  final List<Map<String, Object?>> jsonBodies = [];
  var _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = chunks.expand((chunk) => chunk).toList(growable: false);
      if (bytes.isNotEmpty) {
        jsonBodies.add(jsonDecode(utf8.decode(bytes)) as Map<String, Object?>);
      }
    }
    final response = responses[_index++];
    final statusCode = response.statusCode;
    if (statusCode != null) {
      throw DioException(
        requestOptions: options,
        response: Response<void>(
          requestOptions: options,
          statusCode: statusCode,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(response.payload ?? const <String, Object?>{}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
