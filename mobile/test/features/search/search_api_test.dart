import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/search/data/search_api.dart';
import 'package:inflap/features/search/domain/search_domain.dart';
import 'package:inflap/features/search/domain/search_event.dart';

void main() {
  test(
    'search sends scope and domains to public smart search endpoint',
    () async {
      final adapter = _JsonAdapter({
        'query': 'almaty',
        'locale': 'ru',
        'topResults': [
          {
            'domain': 'place',
            'entityId': 'place-1',
            'title': 'Алматы',
            'deepLink': '/places/place-1',
            'score': 1.2,
          },
        ],
        'groups': {
          'places': {
            'items': [
              {
                'domain': 'place',
                'entityId': 'place-1',
                'title': 'Алматы',
                'deepLink': '/places/place-1',
                'score': 1.2,
              },
            ],
            'nextPageToken': 'places-next',
            'hasMore': true,
          },
          'activities': {'items': [], 'hasMore': false},
          'excursions': {'items': [], 'hasMore': false},
          'guides': {'items': [], 'hasMore': false},
          'communities': {'items': [], 'hasMore': false},
          'users': {'items': [], 'hasMore': false},
        },
        'nextPageToken': 'next',
      });
      final api = SearchApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.search(
        query: '  almaty  ',
        scope: SearchScope.global,
        domains: const [SearchDomain.place, SearchDomain.guide],
        locale: 'ru',
        latitude: 43.238949,
        longitude: 76.889709,
        pageSize: 12,
        groupPageSize: 5,
        pageToken: 'cursor',
      );

      expect(adapter.path, '/search');
      expect(adapter.queryParameters['q'], 'almaty');
      expect(adapter.queryParameters['scope'], 'global');
      expect(adapter.queryParameters['domains'], 'place,guide');
      expect(adapter.queryParameters['locale'], 'ru');
      expect(adapter.queryParameters['lat'], '43.238949');
      expect(adapter.queryParameters['lng'], '76.889709');
      expect(adapter.queryParameters['page_size'], '12');
      expect(adapter.queryParameters['group_page_size'], '5');
      expect(adapter.queryParameters['page_token'], 'cursor');
      expect(adapter.requiresAuth, isFalse);
      expect(adapter.optionalAuth, isTrue);
      expect(page.topResults.single.domain, SearchDomain.place);
      expect(page.groups.places.items.single.title, 'Алматы');
      expect(page.groups.places.nextPageToken, 'places-next');
      expect(page.groups.places.hasMore, isTrue);
      expect(page.nextPageToken, 'next');
    },
  );

  test('suggest sends scope to suggestions endpoint', () async {
    final adapter = _JsonAdapter({
      'query': 'alm',
      'suggestions': [
        {
          'domain': 'place',
          'entityId': 'place-1',
          'text': 'Almaty',
          'deepLink': '/places/place-1',
        },
      ],
    });
    final api = SearchApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final suggestions = await api.suggest(
      query: 'alm',
      scope: SearchScope.place,
      limit: 5,
    );

    expect(adapter.path, '/search/suggest');
    expect(adapter.queryParameters['q'], 'alm');
    expect(adapter.queryParameters['scope'], 'place');
    expect(adapter.queryParameters['limit'], '5');
    expect(adapter.optionalAuth, isTrue);
    expect(suggestions.single.text, 'Almaty');
    expect(suggestions.single.domain, SearchDomain.place);
  });

  test('trackEvent posts privacy-safe search event payload', () async {
    final adapter = _JsonAdapter({'status': 'accepted'});
    final api = SearchApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    await api.trackEvent(
      const SearchTrackingEvent(
        type: SearchTrackingEventType.resultClicked,
        searchSessionId: 'session-1',
        query: 'almaty',
        scope: SearchScope.global,
        domain: SearchDomain.place,
        entityId: 'place-1',
        resultPosition: 2,
        locale: 'ru',
      ),
    );

    expect(adapter.path, '/search/events');
    expect(adapter.method, 'POST');
    expect(adapter.optionalAuth, isTrue);
    expect(adapter.jsonBody['eventType'], 'result_clicked');
    expect(adapter.jsonBody['searchSessionId'], 'session-1');
    expect(adapter.jsonBody['query'], 'almaty');
    expect(adapter.jsonBody['scope'], 'global');
    expect(adapter.jsonBody['domain'], 'place');
    expect(adapter.jsonBody['entityId'], 'place-1');
    expect(adapter.jsonBody['resultPosition'], 2);
    expect(adapter.jsonBody['locale'], 'ru');
  });
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.payload);

  final Map<String, Object?> payload;
  String? path;
  String? method;
  Map<String, String> queryParameters = const {};
  Map<String, Object?> jsonBody = const {};
  bool? requiresAuth;
  bool? optionalAuth;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    method = options.method;
    queryParameters = options.queryParameters.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    if (options.data is Map) {
      jsonBody = (options.data as Map).cast<String, Object?>();
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

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<String?> getSessionId() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {}

  @override
  Future<void> deleteTokens() async {}
}
