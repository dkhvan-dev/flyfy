import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/api_client.dart';
import 'package:superapp/core/storage/secure_storage.dart';
import 'package:superapp/features/guides/data/guide_discovery_api.dart';

void main() {
  test(
    'listPublicGuides uses public guide-service endpoint with query params',
    () async {
      final adapter = _GuideJsonAdapter({
        'total': 12,
        'limit': 8,
        'offset': 16,
        'items': [
          {
            'guideProfile': {
              'id': 'guide-1',
              'userId': 'user-1',
              'type': 'INDEPENDENT',
              'status': 'ACTIVE',
              'headline': 'Mountain Guide',
              'about': 'Alpine and city routes',
              'experienceYears': 8,
              'isPrivateGuideAvailable': true,
              'isActivityHostAvailable': true,
              'isExcursionGuideAvailable': true,
              'ratingAvg': 4.9,
              'reviewsCount': 42,
            },
            'userProfile': {
              'userId': 'user-1',
              'displayName': 'Julian Vane',
              'avatarFileId': 'avatar-file-id',
              'locale': 'en',
              'timezone': 'Asia/Almaty',
              'isPublic': true,
            },
            'languages': [
              {'languageCode': 'en'},
            ],
            'specializations': [
              {'specializationCode': 'mountain_guide'},
            ],
          },
        ],
      });
      final api = GuideDiscoveryApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.listPublicGuides(
        limit: 8,
        offset: 16,
        query: 'mountain',
        sort: 'experience_desc',
        minRating: 4.5,
        minExperienceYears: 3,
        countryCodes: const ['KZ'],
        languageCodes: const ['en', 'ru'],
        specializationCodes: const ['mountain_guide'],
      );

      expect(adapter.lastOptions?.path, '/guides/public');
      expect(adapter.lastOptions?.extra['requiresAuth'], isFalse);
      expect(adapter.lastOptions?.queryParameters['limit'], 8);
      expect(adapter.lastOptions?.queryParameters['offset'], 16);
      expect(adapter.lastOptions?.queryParameters['q'], 'mountain');
      expect(adapter.lastOptions?.queryParameters['sort'], 'experience_desc');
      expect(adapter.lastOptions?.queryParameters['minRating'], 4.5);
      expect(adapter.lastOptions?.queryParameters['minExperienceYears'], 3);
      expect(adapter.lastOptions?.queryParameters['countries'], 'KZ');
      expect(adapter.lastOptions?.queryParameters['languages'], 'en,ru');
      expect(
        adapter.lastOptions?.queryParameters['specializations'],
        'mountain_guide',
      );
      expect(page.total, 12);
      expect(page.limit, 8);
      expect(page.offset, 16);
      expect(page.items, hasLength(1));
      expect(page.items.single.displayName, 'Julian Vane');
      expect(page.items.single.avatarFileId, 'avatar-file-id');
      expect(page.items.single.languageCodes, ['en']);
      expect(page.items.single.specializationCodes, ['mountain_guide']);
    },
  );
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _GuideJsonAdapter implements HttpClientAdapter {
  _GuideJsonAdapter(this.payload);

  final Map<String, Object?> payload;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
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
