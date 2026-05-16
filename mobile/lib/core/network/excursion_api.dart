import 'package:dio/dio.dart';

import '../../features/excursions/models/create_excursion_request.dart';
import '../../features/excursions/models/create_excursion_booking_request.dart';
import '../../features/excursions/models/excursion_vm.dart';
import 'api_client.dart';

class ExcursionApi {
  ExcursionApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ExcursionVm>> getExcursions({
    int limit = 50,
    int offset = 0,
    String? query,
    String? categorySlug,
    String? cityName,
  }) async {
    final response = await _apiClient.dio.get(
      '/excursion-products',
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
        .map(ExcursionVm.fromJson)
        .toList(growable: false);
  }

  Future<ExcursionVm> getExcursionById(String excursionId) async {
    final encodedExcursionId = Uri.encodeComponent(excursionId);
    final response = await _apiClient.dio.get(
      '/excursion-products/$encodedExcursionId',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final offersPage = await getExcursionOffers(excursionId);

    return ExcursionVm.fromJson(
      response.data as Map<String, dynamic>,
      offers: offersPage.items,
    );
  }

  Future<ExcursionOffersPage> getExcursionOffers(
    String excursionId, {
    int limit = 20,
    int offset = 0,
    String? query,
    String? sort,
    String? sortDirection,
    String? languageCode,
    double? priceMax,
    int? maxGroupSizeMin,
    String? preferredGuideUserId,
  }) async {
    final encodedExcursionId = Uri.encodeComponent(excursionId);
    final response = await _apiClient.dio.get(
      '/excursion-products/$encodedExcursionId/offers',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((sortDirection ?? '').trim().isNotEmpty)
          'sortDirection': sortDirection!.trim(),
        if ((languageCode ?? '').trim().isNotEmpty)
          'languageCode': languageCode!.trim(),
        if (priceMax != null) 'priceMax': priceMax,
        if (maxGroupSizeMin != null) 'maxGroupSizeMin': maxGroupSizeMin,
        if ((preferredGuideUserId ?? '').trim().isNotEmpty)
          'preferredGuideUserId': preferredGuideUserId!.trim(),
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return ExcursionOffersPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ExcursionOfferVm.fromJson)
          .toList(growable: false),
      hasMore: data is Map<String, dynamic> && data['hasMore'] == true,
    );
  }

  Future<ExcursionVm> createExcursion(CreateExcursionRequest request) async {
    final response = await _apiClient.dio.post(
      '/me/excursions',
      data: request.toJson(),
    );

    return ExcursionVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionVm> getMyExcursion(String excursionId) async {
    final encodedExcursionId = Uri.encodeComponent(excursionId);
    final response =
        await _apiClient.dio.get('/me/excursions/$encodedExcursionId');

    return ExcursionVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionVm> updateExcursionOffer(
    String legacyExcursionId,
    CreateExcursionRequest request,
  ) async {
    final encodedExcursionId = Uri.encodeComponent(legacyExcursionId);
    final response = await _apiClient.dio.put(
      '/me/excursions/$encodedExcursionId',
      data: request.toJson(),
    );

    return ExcursionVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionVm> publishExcursion(String excursionId) async {
    final response =
        await _apiClient.dio.post('/me/excursions/$excursionId/publish');

    return ExcursionVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createExcursionBooking(
    CreateExcursionBookingRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/me/excursion-bookings',
      data: request.toJson(),
    );

    return response.data as Map<String, dynamic>;
  }
}

class ExcursionOffersPage {
  const ExcursionOffersPage({required this.items, required this.hasMore});

  final List<ExcursionOfferVm> items;
  final bool hasMore;
}
