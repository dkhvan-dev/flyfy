import 'package:dio/dio.dart';

import '../../features/tours/models/create_tour_request.dart';
import '../../features/tours/models/tour_vm.dart';
import 'api_client.dart';

class TourApi {
  TourApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<TourVm>> getTours({
    int limit = 50,
    int offset = 0,
    String? query,
    String? categorySlug,
    String? cityName,
  }) async {
    final response = await _apiClient.dio.get(
      '/tours',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
        if ((categorySlug ?? '').trim().isNotEmpty)
          'categorySlug': categorySlug!.trim(),
        if ((cityName ?? '').trim().isNotEmpty) 'cityName': cityName!.trim(),
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(TourVm.fromJson)
        .toList(growable: false);
  }

  Future<TourVm> createTour(CreateTourRequest request) async {
    final response = await _apiClient.dio.post(
      '/me/tours',
      data: request.toJson(),
    );

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TourVm> publishTour(String tourId) async {
    final response = await _apiClient.dio.post('/me/tours/$tourId/publish');

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }
}
