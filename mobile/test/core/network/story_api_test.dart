import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/api_client.dart';
import 'package:superapp/core/network/story_api.dart';
import 'package:superapp/core/storage/secure_storage.dart';

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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
