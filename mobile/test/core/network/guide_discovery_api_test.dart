import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/guides/data/guide_discovery_api.dart';

void main() {
  test(
    'listPublicGuides uses public guide-service endpoint with query params',
    () async {
      final adapter = _GuideJsonAdapter(
        guidesPayload: {
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
                'firstName': 'Julian',
                'lastName': 'Vane',
                'displayName': '@julian_guide',
                'avatarFileId': 'avatar-file-id',
                'locale': 'en',
                'timezone': 'Asia/Almaty',
              },
              'languages': [
                {'languageCode': 'en'},
              ],
              'specializations': [
                {'specializationCode': 'mountain_guide'},
              ],
            },
          ],
        },
        languagePayload: {
          'items': [
            {
              'guideUserId': 'user-1',
              'languageCodes': ['ru', 'kk', 'ru'],
            },
          ],
        },
      );
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
        cityId: 'almaty',
        cityName: 'Алматы',
        cityCountryCode: 'KZ',
        countryCodes: const ['KZ'],
        languageCodes: const ['en', 'ru'],
        specializationCodes: const ['mountain_guide'],
      );

      expect(adapter.requests.map((request) => request.path), [
        '/guides/public',
        '/guides/excursion-languages',
      ]);
      final publicRequest = adapter.requests.first;
      final languageRequest = adapter.requests.last;
      expect(publicRequest.extra['requiresAuth'], isFalse);
      expect(publicRequest.queryParameters['limit'], 8);
      expect(publicRequest.queryParameters['offset'], 16);
      expect(publicRequest.queryParameters['q'], 'mountain');
      expect(publicRequest.queryParameters['sort'], 'experience_desc');
      expect(publicRequest.queryParameters['minRating'], 4.5);
      expect(publicRequest.queryParameters['minExperienceYears'], 3);
      expect(publicRequest.queryParameters.containsKey('cityId'), isFalse);
      expect(publicRequest.queryParameters['cityName'], 'Алматы');
      expect(publicRequest.queryParameters['cityCountryCode'], 'KZ');
      expect(publicRequest.queryParameters['countries'], 'KZ');
      expect(publicRequest.queryParameters['languages'], 'en,ru');
      expect(
        publicRequest.queryParameters['specializations'],
        'mountain_guide',
      );
      expect(languageRequest.extra['requiresAuth'], isFalse);
      expect(languageRequest.queryParameters['guideUserIds'], 'user-1');
      expect(page.total, 12);
      expect(page.limit, 8);
      expect(page.offset, 16);
      expect(page.items, hasLength(1));
      expect(page.items.single.firstName, 'Julian');
      expect(page.items.single.lastName, 'Vane');
      expect(page.items.single.displayName, '@julian_guide');
      expect(page.items.single.preferredName, 'Vane Julian');
      expect(page.items.single.avatarFileId, 'avatar-file-id');
      expect(page.items.single.languageCodes, ['en']);
      expect(page.items.single.excursionLanguageCodes, ['ru', 'kk']);
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
  _GuideJsonAdapter({
    required this.guidesPayload,
    this.languagePayload = const {'items': []},
  });

  final Map<String, Object?> guidesPayload;
  final Map<String, Object?> languagePayload;
  RequestOptions? lastOptions;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    requests.add(options);
    final payload = options.path == '/guides/excursion-languages'
        ? languagePayload
        : guidesPayload;
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
