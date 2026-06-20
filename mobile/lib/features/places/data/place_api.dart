import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/place_vm.dart';
import '../models/place_review_vm.dart';

class PlaceApi {
  PlaceApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<({List<PlaceVm> items, int total})> getPlaces({
    String? search,
    String? category,
    String? countryCode,
    String? cityId,
    String? accessCityId,
    double? priceMin,
    double? priceMax,
    int? durationMin,
    int? durationMax,
    String? durationUnit,
    int? spotsMin,
    double? minRating,
    String? sort,
    String? locale,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      params['countryCode'] = countryCode;
    }
    if (cityId != null && cityId.isNotEmpty) {
      params['cityId'] = cityId;
    }
    if (accessCityId != null && accessCityId.isNotEmpty) {
      params['accessCityId'] = accessCityId;
    }
    if (priceMin != null) params['priceMin'] = priceMin;
    if (priceMax != null) params['priceMax'] = priceMax;
    if (durationMin != null) params['durationMin'] = durationMin;
    if (durationMax != null) params['durationMax'] = durationMax;
    if (durationUnit != null) params['durationUnit'] = durationUnit;
    if (spotsMin != null) params['spotsMin'] = spotsMin;
    if (minRating != null) params['minRating'] = minRating;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (locale != null && locale.isNotEmpty) params['locale'] = locale;

    final response = await _apiClient.dio.get(
      '/places',
      queryParameters: params,
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlaceVm.fromJson)
        .toList();
    final total = data['total'] as int? ?? items.length;

    return (items: items, total: total);
  }

  Future<PlaceVm> getPlace(String id, {String? locale}) async {
    final params = <String, dynamic>{};
    if (locale != null && locale.isNotEmpty) {
      params['locale'] = locale;
    }

    final response = await _apiClient.dio.get(
      '/places/$id',
      queryParameters: params.isEmpty ? null : params,
      options: Options(extra: const {'requiresAuth': false}),
    );
    return PlaceVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<({List<PlaceReviewVm> items, int total})> getReviews(
    String placeId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/places/$placeId/reviews',
      queryParameters: {'limit': limit, 'offset': offset},
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlaceReviewVm.fromJson)
        .toList();
    final total = data['total'] as int? ?? items.length;

    return (items: items, total: total);
  }

  Future<PlaceReviewVm> createReview(
    String placeId, {
    required double rating,
    required String comment,
    List<PlaceReviewMediaInput> media = const [],
  }) async {
    final response = await _apiClient.dio.post(
      '/places/$placeId/reviews',
      data: {
        'rating': rating,
        'comment': comment,
        'media': media.map((item) => item.toJson()).toList(growable: false),
      },
    );
    return PlaceReviewVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlaceReviewVm?> getMyReview(String placeId) async {
    try {
      final response = await _apiClient.dio.get('/places/$placeId/reviews/me');
      return PlaceReviewVm.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}

class PlaceReviewMediaInput {
  const PlaceReviewMediaInput({
    required this.fileId,
    required this.mediaType,
    required this.position,
  });

  final String fileId;
  final String mediaType;
  final int position;

  Map<String, dynamic> toJson() {
    return {'fileId': fileId, 'mediaType': mediaType, 'position': position};
  }
}
