import 'package:dio/dio.dart';

import '../../features/excursions/models/create_excursion_request.dart';
import '../../features/excursions/models/create_excursion_booking_request.dart';
import '../../features/excursions/models/create_excursion_review_request.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../features/excursions/models/excursion_vm.dart';
import 'api_client.dart';

class ExcursionApi {
  ExcursionApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ExcursionVm>> getExcursions({
    int limit = 50,
    int offset = 0,
    String? query,
    String? landmarkId,
    String? categorySlug,
    String? cityName,
    String? departureCityId,
  }) async {
    final response = await _apiClient.dio.get(
      '/excursion-products',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
        if ((landmarkId ?? '').trim().isNotEmpty)
          'landmarkId': landmarkId!.trim(),
        if ((categorySlug ?? '').trim().isNotEmpty)
          'categorySlug': categorySlug!.trim(),
        if ((cityName ?? '').trim().isNotEmpty) 'cityName': cityName!.trim(),
        if ((departureCityId ?? '').trim().isNotEmpty)
          'departureCityId': departureCityId!.trim(),
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items =
        (data is Map<String, dynamic>
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
    final items =
        (data is Map<String, dynamic>
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
    final response = await _apiClient.dio.get(
      '/me/excursions/$encodedExcursionId',
    );

    return ExcursionVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionsPage> getMyExcursions({
    int limit = 50,
    int offset = 0,
    List<String> statuses = const [],
  }) async {
    final normalizedStatuses = statuses
        .map((status) => status.trim().toUpperCase())
        .where((status) => status.isNotEmpty)
        .toList(growable: false);
    final response = await _apiClient.dio.get(
      '/me/excursions',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (normalizedStatuses.isNotEmpty)
          'status': normalizedStatuses.join(','),
      },
    );

    final data = response.data;
    final items =
        (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return ExcursionsPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ExcursionVm.fromJson)
          .toList(growable: false),
      hasMore: data is Map<String, dynamic> && data['hasMore'] == true,
    );
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
    return submitExcursionForPublishing(excursionId);
  }

  Future<ExcursionVm> submitExcursionForPublishing(String excursionId) async {
    final encodedExcursionId = Uri.encodeComponent(excursionId);
    final response = await _apiClient.dio.post(
      '/me/excursions/$encodedExcursionId/submit-for-publish',
    );

    return ExcursionVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionVm> archiveExcursionOffer(String excursionId) async {
    final encodedExcursionId = Uri.encodeComponent(excursionId);
    final response = await _apiClient.dio.post(
      '/me/excursions/$encodedExcursionId/archive',
    );

    return ExcursionVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExcursionOffer(String excursionId) async {
    final encodedExcursionId = Uri.encodeComponent(excursionId);
    await _apiClient.dio.delete('/me/excursions/$encodedExcursionId');
  }

  Future<ExcursionBookingVm> createExcursionBooking(
    CreateExcursionBookingRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/me/excursion-bookings',
      data: request.toJson(),
    );

    return ExcursionBookingVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionBookingVm> updateExcursionBookingGuests(
    String bookingId, {
    required int adults,
    required int children,
  }) async {
    final encodedBookingId = Uri.encodeComponent(bookingId);
    final response = await _apiClient.dio.patch(
      '/me/excursion-bookings/$encodedBookingId',
      data: <String, dynamic>{'adults': adults, 'children': children},
    );

    return ExcursionBookingVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionBookingVm> cancelExcursionBooking(
    String bookingId, {
    String reason = '',
  }) async {
    final encodedBookingId = Uri.encodeComponent(bookingId);
    final response = await _apiClient.dio.post(
      '/me/excursion-bookings/$encodedBookingId/cancel',
      data: <String, dynamic>{'reason': reason},
    );

    return ExcursionBookingVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExcursionBookingsPage> getMyExcursionBookings({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/excursion-bookings',
      queryParameters: <String, dynamic>{'limit': limit, 'offset': offset},
    );

    final data = response.data;
    final items =
        (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return ExcursionBookingsPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ExcursionBookingVm.fromJson)
          .toList(growable: false),
      hasMore: data is Map<String, dynamic> && data['hasMore'] == true,
    );
  }

  Future<ExcursionBookingsPage> getMyGuideExcursionBookings({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/guide-excursion-bookings',
      queryParameters: <String, dynamic>{'limit': limit, 'offset': offset},
    );

    final data = response.data;
    final items =
        (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    return ExcursionBookingsPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ExcursionBookingVm.fromJson)
          .toList(growable: false),
      hasMore: data is Map<String, dynamic> && data['hasMore'] == true,
    );
  }

  Future<ExcursionReviewVm> createExcursionReview(
    String bookingId,
    CreateExcursionReviewRequest request,
  ) async {
    final encodedBookingId = Uri.encodeComponent(bookingId);
    final response = await _apiClient.dio.post(
      '/me/excursion-bookings/$encodedBookingId/review',
      data: request.toJson(),
    );
    return ExcursionReviewVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BookingReviewsResultVm> saveBookingReviews(
    String bookingId,
    SaveBookingReviewsRequest request,
  ) async {
    final encodedBookingId = Uri.encodeComponent(bookingId);
    final response = await _apiClient.dio.put(
      '/me/excursion-bookings/$encodedBookingId/reviews',
      data: request.toJson(),
    );
    return BookingReviewsResultVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ExcursionReviewsPage> getExcursionReviews({
    String? productId,
    String? landmarkId,
    String? guideUserId,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) async {
    final endpoint = (productId ?? '').trim().isNotEmpty
        ? '/excursion-products/${Uri.encodeComponent(productId!.trim())}/reviews'
        : '/excursion-reviews';
    final response = await _apiClient.dio.get(
      endpoint,
      queryParameters: <String, dynamic>{
        if ((landmarkId ?? '').trim().isNotEmpty)
          'landmarkId': landmarkId!.trim(),
        if ((guideUserId ?? '').trim().isNotEmpty)
          'guideUserId': guideUserId!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        'limit': limit,
        'offset': offset,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items =
        (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];
    return ExcursionReviewsPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ExcursionReviewVm.fromJson)
          .toList(growable: false),
      hasMore: data is Map<String, dynamic> && data['hasMore'] == true,
    );
  }

  Future<ExcursionReviewsPage> getGuideExcursionReviews({
    required String guideUserId,
    int limit = 10,
    int offset = 0,
    String sort = 'rating_desc',
  }) {
    return getExcursionReviews(
      guideUserId: guideUserId,
      sort: sort,
      limit: limit,
      offset: offset,
    );
  }

  Future<GuideReviewsPage> getGuideReviews({
    required String guideUserId,
    int limit = 10,
    int offset = 0,
    String sort = 'latest',
  }) async {
    final response = await _apiClient.dio.get(
      '/guide-reviews',
      queryParameters: <String, dynamic>{
        'guideUserId': guideUserId.trim(),
        if (sort.trim().isNotEmpty) 'sort': sort.trim(),
        'limit': limit,
        'offset': offset,
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items =
        (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];
    return GuideReviewsPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(GuideReviewVm.fromJson)
          .toList(growable: false),
      hasMore: data is Map<String, dynamic> && data['hasMore'] == true,
    );
  }
}

class ExcursionOffersPage {
  const ExcursionOffersPage({required this.items, required this.hasMore});

  final List<ExcursionOfferVm> items;
  final bool hasMore;
}

class ExcursionsPage {
  const ExcursionsPage({required this.items, required this.hasMore});

  final List<ExcursionVm> items;
  final bool hasMore;
}

class ExcursionBookingsPage {
  const ExcursionBookingsPage({required this.items, required this.hasMore});

  final List<ExcursionBookingVm> items;
  final bool hasMore;
}

class ExcursionReviewsPage {
  const ExcursionReviewsPage({required this.items, required this.hasMore});

  final List<ExcursionReviewVm> items;
  final bool hasMore;
}

class GuideReviewsPage {
  const GuideReviewsPage({required this.items, required this.hasMore});

  final List<GuideReviewVm> items;
  final bool hasMore;
}

class BookingReviewsResultVm {
  const BookingReviewsResultVm({this.excursionReview, this.guideReview});

  final ExcursionReviewVm? excursionReview;
  final GuideReviewVm? guideReview;

  factory BookingReviewsResultVm.fromJson(Map<String, dynamic> json) {
    return BookingReviewsResultVm(
      excursionReview: json['excursionReview'] is Map<String, dynamic>
          ? ExcursionReviewVm.fromJson(
              json['excursionReview'] as Map<String, dynamic>,
            )
          : null,
      guideReview: json['guideReview'] is Map<String, dynamic>
          ? GuideReviewVm.fromJson(json['guideReview'] as Map<String, dynamic>)
          : null,
    );
  }
}
