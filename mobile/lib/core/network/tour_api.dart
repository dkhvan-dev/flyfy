import 'package:dio/dio.dart';

import '../../features/tours/models/create_tour_request.dart';
import '../../features/tours/models/create_tour_booking_request.dart';
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
      '/tour-products',
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

  Future<TourVm> getTourById(String tourId) async {
    final encodedTourId = Uri.encodeComponent(tourId);
    final response = await _apiClient.dio.get(
      '/tour-products/$encodedTourId',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final offersPage = await getTourOffers(tourId);

    return TourVm.fromJson(
      response.data as Map<String, dynamic>,
      offers: offersPage.items,
    );
  }

  Future<TourOffersPage> getTourOffers(
    String tourId, {
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
    final encodedTourId = Uri.encodeComponent(tourId);
    final response = await _apiClient.dio.get(
      '/tour-products/$encodedTourId/offers',
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

    return TourOffersPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(TourOfferVm.fromJson)
          .toList(growable: false),
      hasMore: data is Map<String, dynamic> && data['hasMore'] == true,
    );
  }

  Future<TourVm> createTour(CreateTourRequest request) async {
    final response = await _apiClient.dio.post(
      '/me/tours',
      data: request.toJson(),
    );

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TourVm> getMyTour(String tourId) async {
    final encodedTourId = Uri.encodeComponent(tourId);
    final response = await _apiClient.dio.get('/me/tours/$encodedTourId');

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TourVm> updateTourOffer(
    String legacyTourId,
    CreateTourRequest request,
  ) async {
    final encodedTourId = Uri.encodeComponent(legacyTourId);
    final response = await _apiClient.dio.put(
      '/me/tours/$encodedTourId',
      data: request.toJson(),
    );

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TourVm> publishTour(String tourId) async {
    final response = await _apiClient.dio.post('/me/tours/$tourId/publish');

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createTourBooking(
    CreateTourBookingRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/me/tour-bookings',
      data: request.toJson(),
    );

    return response.data as Map<String, dynamic>;
  }
}

class TourOffersPage {
  const TourOffersPage({required this.items, required this.hasMore});

  final List<TourOfferVm> items;
  final bool hasMore;
}
