import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/excursion_api.dart';
import '../core/network/excursion_schedule_api.dart';
import '../features/excursions/models/create_excursion_booking_request.dart';
import '../features/excursions/models/create_excursion_review_request.dart';
import '../features/excursions/models/create_excursion_request.dart';
import '../features/excursions/models/excursion_booking_vm.dart';
import '../features/excursions/models/excursion_schedule_vm.dart';
import '../features/excursions/models/excursion_vm.dart';
import '../features/profile/data/guide_api.dart';
import '../features/profile/models/guide_profile_vm.dart';

enum ExcursionActionState { idle, loading, success, error }

enum ExcursionListState { initial, loading, success, error }

enum ExcursionDetailState { initial, loading, success, error }

class ExcursionProvider extends ChangeNotifier {
  ExcursionProvider({
    ExcursionApi? excursionApi,
    ExcursionScheduleApi? scheduleApi,
    GuideApi? guideApi,
  })  : _excursionApi = excursionApi ?? ExcursionApi(),
        _guideApi = guideApi ?? GuideApi(),
        _scheduleApi = scheduleApi ?? ExcursionScheduleApi();

  static const _marketplaceRefreshAttempts = 3;
  static const _marketplaceRefreshRetryDelay = Duration(milliseconds: 150);
  static const _guideDashboardOfferStatuses = <String>[
    'PUBLISHED',
    'DRAFT',
    'PENDING_REVIEW',
    'REJECTED',
    'ARCHIVED',
  ];

  final ExcursionApi _excursionApi;
  final GuideApi _guideApi;
  final ExcursionScheduleApi _scheduleApi;

  ExcursionListState _listState = ExcursionListState.initial;
  List<ExcursionVm> _excursions = const [];
  String? _listErrorMessage;
  bool _isRefreshing = false;

  ExcursionDetailState _detailState = ExcursionDetailState.initial;
  String? _detailExcursionId;
  ExcursionVm? _selectedExcursion;
  String? _detailErrorMessage;
  final Map<String, ExcursionVm> _excursionDetailsById = {};
  final Set<String> _loadingDetailExcursionIds = <String>{};
  final Map<String, String> _detailErrorsByExcursionId = {};

  ExcursionActionState _actionState = ExcursionActionState.idle;
  String? _actionErrorMessage;
  ExcursionVm? _lastCreatedExcursion;

  ExcursionListState _bookingListState = ExcursionListState.initial;
  List<ExcursionBookingVm> _myExcursionBookings = const [];
  String? _bookingListErrorMessage;
  bool _isBookingListRefreshing = false;

  ExcursionListState _guideDashboardState = ExcursionListState.initial;
  List<ExcursionVm> _myGuideExcursions = const [];
  List<ExcursionBookingVm> _myGuideExcursionBookings = const [];
  GuideProfileVm? _myGuideProfile;
  String? _guideDashboardErrorMessage;
  bool _isGuideDashboardRefreshing = false;

  final Map<String, List<ExcursionReviewVm>> _reviewsByProductId = {};
  final Map<String, List<ExcursionReviewVm>> _reviewsByLandmarkId = {};

  ExcursionListState get listState => _listState;
  List<ExcursionVm> get excursions => _excursions;
  String? get listErrorMessage => _listErrorMessage;
  bool get isRefreshing => _isRefreshing;

  ExcursionDetailState get detailState => _detailState;
  ExcursionVm? get selectedExcursion => _selectedExcursion;
  String? get detailErrorMessage => _detailErrorMessage;

  ExcursionVm? excursionDetailsFor(String excursionId) {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) return null;
    return _excursionDetailsById[trimmedExcursionId];
  }

  bool isDetailLoadingFor(String excursionId) {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) return false;
    return _loadingDetailExcursionIds.contains(trimmedExcursionId);
  }

  bool isDetailErrorFor(String excursionId) {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) return false;
    return !_excursionDetailsById.containsKey(trimmedExcursionId) &&
        _detailErrorsByExcursionId.containsKey(trimmedExcursionId);
  }

  String? detailErrorMessageFor(String excursionId) {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) return null;
    return _detailErrorsByExcursionId[trimmedExcursionId];
  }

  ExcursionActionState get actionState => _actionState;
  String? get actionErrorMessage => _actionErrorMessage;
  ExcursionVm? get lastCreatedExcursion => _lastCreatedExcursion;

  ExcursionListState get bookingListState => _bookingListState;
  List<ExcursionBookingVm> get myExcursionBookings => _myExcursionBookings;
  String? get bookingListErrorMessage => _bookingListErrorMessage;
  bool get isBookingListRefreshing => _isBookingListRefreshing;

  ExcursionListState get guideDashboardState => _guideDashboardState;
  List<ExcursionVm> get myGuideExcursions => _myGuideExcursions;
  List<ExcursionBookingVm> get myGuideExcursionBookings =>
      _myGuideExcursionBookings;
  GuideProfileVm? get myGuideProfile => _myGuideProfile;
  String? get guideDashboardErrorMessage => _guideDashboardErrorMessage;
  bool get isGuideDashboardRefreshing => _isGuideDashboardRefreshing;

  List<ExcursionReviewVm> excursionReviewsForProduct(String productId) {
    return _reviewsByProductId[productId.trim()] ?? const [];
  }

  List<ExcursionReviewVm> excursionReviewsForLandmark(String landmarkId) {
    return _reviewsByLandmarkId[landmarkId.trim()] ?? const [];
  }

  Future<void> loadExcursions({
    String? query,
    String? landmarkId,
    String? categorySlug,
    String? cityName,
    String? departureCityId,
  }) async {
    if (_listState == ExcursionListState.loading || _isRefreshing) {
      return;
    }

    final hasCachedExcursions = _excursions.isNotEmpty;
    if (hasCachedExcursions) {
      _isRefreshing = true;
    } else {
      _listState = ExcursionListState.loading;
    }
    _listErrorMessage = null;
    notifyListeners();

    try {
      _excursions = await _excursionApi.getExcursions(
        query: query,
        landmarkId: landmarkId,
        categorySlug: categorySlug,
        cityName: cityName,
        departureCityId: departureCityId,
      );
      _listState = ExcursionListState.success;
    } on DioException catch (e) {
      _listErrorMessage = DioErrorMapper.toMessage(e);
      if (!hasCachedExcursions) {
        _listState = ExcursionListState.error;
      }
    } catch (_) {
      _listErrorMessage = 'Failed to load excursions';
      if (!hasCachedExcursions) {
        _listState = ExcursionListState.error;
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshExcursions({
    String? query,
    String? landmarkId,
    String? categorySlug,
    String? cityName,
    String? departureCityId,
  }) {
    return loadExcursions(
      query: query,
      landmarkId: landmarkId,
      categorySlug: categorySlug,
      cityName: cityName,
      departureCityId: departureCityId,
    );
  }

  Future<ExcursionVm?> findFirstExcursionForAttraction(
    String attractionId,
  ) async {
    final trimmedAttractionId = attractionId.trim();
    if (trimmedAttractionId.isEmpty) return null;

    final items = await _excursionApi.getExcursions(
      limit: 1,
      landmarkId: trimmedAttractionId,
    );
    return items.isEmpty ? null : items.first;
  }

  Future<void> loadMyExcursionBookings({bool force = false}) async {
    if (!force &&
        (_bookingListState == ExcursionListState.loading ||
            _isBookingListRefreshing)) {
      return;
    }

    final hasCachedBookings = _myExcursionBookings.isNotEmpty;
    if (hasCachedBookings) {
      _isBookingListRefreshing = true;
    } else {
      _bookingListState = ExcursionListState.loading;
    }
    _bookingListErrorMessage = null;
    notifyListeners();

    try {
      final page = await _excursionApi.getMyExcursionBookings(limit: 100);
      _myExcursionBookings = page.items;
      _bookingListState = ExcursionListState.success;
    } on DioException catch (e) {
      _bookingListErrorMessage = DioErrorMapper.toMessage(e);
      if (!hasCachedBookings) {
        _bookingListState = ExcursionListState.error;
      }
    } catch (_) {
      _bookingListErrorMessage = 'Failed to load excursion bookings';
      if (!hasCachedBookings) {
        _bookingListState = ExcursionListState.error;
      }
    } finally {
      _isBookingListRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshMyExcursionBookings() {
    return loadMyExcursionBookings(force: true);
  }

  Future<void> loadGuideDashboardData({bool force = false}) async {
    if (!force &&
        (_guideDashboardState == ExcursionListState.loading ||
            _isGuideDashboardRefreshing)) {
      return;
    }

    final hasCachedData = _myGuideProfile != null ||
        _myGuideExcursions.isNotEmpty ||
        _myGuideExcursionBookings.isNotEmpty;
    if (hasCachedData) {
      _isGuideDashboardRefreshing = true;
    } else {
      _guideDashboardState = ExcursionListState.loading;
    }
    _guideDashboardErrorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object?>([
        _excursionApi.getMyExcursions(
          limit: 100,
          statuses: _guideDashboardOfferStatuses,
        ),
        _excursionApi.getMyGuideExcursionBookings(limit: 100),
        _guideApi.getMyGuideProfileOrNull(),
      ]);
      final excursionsPage = results[0] as ExcursionsPage;
      final bookingsPage = results[1] as ExcursionBookingsPage;
      final guideProfile = results[2] as GuideProfileVm?;

      _myGuideExcursions = excursionsPage.items;
      _myGuideExcursionBookings = bookingsPage.items;
      _myGuideProfile = guideProfile;
      _guideDashboardState = ExcursionListState.success;
    } on DioException catch (e) {
      _guideDashboardErrorMessage = DioErrorMapper.toMessage(e);
      if (!hasCachedData) {
        _guideDashboardState = ExcursionListState.error;
      }
    } catch (_) {
      _guideDashboardErrorMessage = 'Failed to load guide dashboard';
      if (!hasCachedData) {
        _guideDashboardState = ExcursionListState.error;
      }
    } finally {
      _isGuideDashboardRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshGuideDashboardData() {
    return loadGuideDashboardData(force: true);
  }

  Future<List<ExcursionScheduleSlotVm>> loadBookableExcursionSchedule({
    required String productId,
    required String offerId,
    required DateTime from,
    required DateTime to,
    required int seats,
  }) {
    return _scheduleApi.getPublicSchedule(
      productId: productId,
      offerId: offerId,
      from: from,
      to: to,
      seats: seats,
    );
  }

  Future<bool> cancelGuideExcursionSlot(
    String slotId, {
    required String reason,
  }) async {
    final trimmedSlotId = slotId.trim();
    final trimmedReason = reason.trim();
    if (trimmedSlotId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion schedule slot id';
      return false;
    }
    if (trimmedReason.isEmpty) {
      _actionErrorMessage = 'Cancellation reason is required';
      return false;
    }

    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      await _scheduleApi.cancelSlot(trimmedSlotId, trimmedReason);
      _myGuideExcursionBookings = _myGuideExcursionBookings.map((booking) {
        final bookingSlotId = (booking.scheduleSlotId ?? '').trim();
        if (bookingSlotId != trimmedSlotId) return booking;
        return booking.copyWith(status: 'CANCELLED');
      }).toList(growable: false);
      _actionState = ExcursionActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to cancel excursion';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> publishExcursionOffer(String excursionId) async {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion id';
      return false;
    }

    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final published = await _excursionApi.publishExcursion(
        trimmedExcursionId,
      );
      _upsertGuideDashboardExcursion(published);
      _actionState = ExcursionActionState.success;
      await loadGuideDashboardData(force: true);
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to publish excursion offer';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> archiveExcursionOffer(String excursionId) async {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion id';
      return false;
    }

    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final archived = await _excursionApi.archiveExcursionOffer(
        trimmedExcursionId,
      );
      _upsertGuideDashboardExcursion(archived);
      _actionState = ExcursionActionState.success;
      await loadGuideDashboardData(force: true);
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to archive excursion offer';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadExcursionDetails(
    String excursionId, {
    ExcursionVm? initialExcursion,
  }) async {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      _detailState = ExcursionDetailState.error;
      _detailErrorMessage = 'Invalid excursion id';
      notifyListeners();
      return;
    }

    final cachedExcursion = _excursionDetailsById[trimmedExcursionId] ??
        initialExcursion ??
        _findCachedExcursion(trimmedExcursionId);
    final hasCachedExcursion = cachedExcursion != null;

    _detailExcursionId = trimmedExcursionId;
    _detailErrorMessage = null;
    _detailErrorsByExcursionId.remove(trimmedExcursionId);
    _loadingDetailExcursionIds.add(trimmedExcursionId);
    if (hasCachedExcursion) {
      _selectedExcursion = cachedExcursion;
      _excursionDetailsById[trimmedExcursionId] = cachedExcursion;
      _detailState = ExcursionDetailState.success;
    } else {
      _selectedExcursion = null;
      _detailState = ExcursionDetailState.loading;
    }
    notifyListeners();

    try {
      final excursion = await _excursionApi.getExcursionById(
        trimmedExcursionId,
      );

      _excursionDetailsById[trimmedExcursionId] = excursion;
      _detailErrorsByExcursionId.remove(trimmedExcursionId);
      if (_detailExcursionId == trimmedExcursionId) {
        _selectedExcursion = excursion;
        _detailState = ExcursionDetailState.success;
        _detailErrorMessage = null;
      }
    } on DioException catch (e) {
      final message = DioErrorMapper.toMessage(e);
      _detailErrorsByExcursionId[trimmedExcursionId] = message;
      if (_detailExcursionId == trimmedExcursionId) {
        _detailErrorMessage = message;
        if (!hasCachedExcursion) {
          _detailState = ExcursionDetailState.error;
        }
      }
    } catch (_) {
      const message = 'Failed to load excursion';
      _detailErrorsByExcursionId[trimmedExcursionId] = message;
      if (_detailExcursionId == trimmedExcursionId) {
        _detailErrorMessage = message;
        if (!hasCachedExcursion) {
          _detailState = ExcursionDetailState.error;
        }
      }
    } finally {
      _loadingDetailExcursionIds.remove(trimmedExcursionId);
      notifyListeners();
    }
  }

  void resetActionState() {
    _actionState = ExcursionActionState.idle;
    _actionErrorMessage = null;
    notifyListeners();
  }

  Future<ExcursionVm?> createDraftExcursion(
    CreateExcursionRequest request,
  ) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final created = await _excursionApi.createExcursion(request);
      _lastCreatedExcursion = created;
      _actionState = ExcursionActionState.success;
      return _lastCreatedExcursion;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to create excursion';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<ExcursionVm?> submitExcursionForPublishing(String excursionId) async {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion id';
      return null;
    }

    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final submitted = await _excursionApi.publishExcursion(
        trimmedExcursionId,
      );
      final refreshedProduct = await _refreshProductAfterMutation(
        submitted,
        preferredLandmarkId: submitted.landmarkId,
      );
      _lastCreatedExcursion = refreshedProduct ?? submitted;
      _actionState = ExcursionActionState.success;
      return _lastCreatedExcursion;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to submit excursion';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<ExcursionVm?> createAndSubmitExcursion(
    CreateExcursionRequest request,
  ) async {
    final created = await createDraftExcursion(request);
    if (created == null) return null;
    return submitExcursionForPublishing(created.id);
  }

  Future<ExcursionVm?> createAndPublishExcursion(
    CreateExcursionRequest request,
  ) {
    return createAndSubmitExcursion(request);
  }

  Future<ExcursionVm?> loadMyExcursionForEdit(String excursionId) async {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion id';
      return null;
    }
    try {
      return await _excursionApi.getMyExcursion(trimmedExcursionId);
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to load excursion';
      return null;
    }
  }

  Future<ExcursionVm?> updateExcursionOffer(
    String legacyExcursionId,
    CreateExcursionRequest request,
  ) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await _excursionApi.updateExcursionOffer(
        legacyExcursionId,
        request,
      );
      final refreshedProduct = await _refreshProductAfterMutation(
        updated,
        preferredProductId: _detailExcursionId,
        preferredLandmarkId: request.landmarkId,
      );
      _actionState = ExcursionActionState.success;
      return refreshedProduct ?? updated;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to update excursion offer';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createExcursionBooking(
    CreateExcursionBookingRequest request,
  ) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final booking = await _excursionApi.createExcursionBooking(request);
      _upsertMyExcursionBooking(booking);
      _actionState = ExcursionActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to book excursion';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateExcursionBookingGuests(
    String bookingId, {
    required int adults,
    required int children,
  }) async {
    final trimmedBookingId = bookingId.trim();
    if (trimmedBookingId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion booking id';
      return false;
    }

    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final booking = await _excursionApi.updateExcursionBookingGuests(
        trimmedBookingId,
        adults: adults,
        children: children,
      );
      _upsertMyExcursionBooking(booking);
      _actionState = ExcursionActionState.success;
      await loadMyExcursionBookings(force: true);
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to update excursion booking';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> cancelExcursionBooking(
    String bookingId, {
    String reason = '',
  }) async {
    final trimmedBookingId = bookingId.trim();
    if (trimmedBookingId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion booking id';
      return false;
    }

    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final booking = await _excursionApi.cancelExcursionBooking(
        trimmedBookingId,
        reason: reason.trim(),
      );
      _upsertMyExcursionBooking(booking);
      _actionState = ExcursionActionState.success;
      await loadMyExcursionBookings(force: true);
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to cancel excursion booking';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<ExcursionReviewVm?> createExcursionReview(
    String bookingId,
    CreateExcursionReviewRequest request,
  ) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final review = await _excursionApi.createExcursionReview(
        bookingId,
        request,
      );
      _upsertBookingReview(bookingId, review);
      _upsertExcursionReviewCache(review);
      _actionState = ExcursionActionState.success;
      return review;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to publish excursion review';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<ExcursionBookingVm?> saveBookingReviews(
    String bookingId,
    SaveBookingReviewsRequest request,
  ) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final result = await _excursionApi.saveBookingReviews(
        bookingId,
        request,
      );
      final booking = _applyBookingReviewsResult(bookingId, result);
      if (result.excursionReview != null) {
        _upsertExcursionReviewCache(result.excursionReview!);
      }
      _actionState = ExcursionActionState.success;
      return booking;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to save excursion reviews';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<ExcursionReviewVm?> saveExcursionReview(
    String bookingId,
    ReviewDraftRequest draft,
  ) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final result = await _excursionApi.saveBookingReviews(
        bookingId,
        SaveBookingReviewsRequest(
          excursionReview: ReviewMutationRequest.fromDraft(draft),
        ),
      );
      _applyBookingReviewsResult(bookingId, result);
      final review = result.excursionReview;
      if (review != null) {
        _upsertExcursionReviewCache(review);
      }
      _actionState = ExcursionActionState.success;
      return review;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to save excursion review';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> deleteExcursionReview(String bookingId, String reviewId) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final result = await _excursionApi.saveBookingReviews(
        bookingId,
        const SaveBookingReviewsRequest(
          excursionReview: ReviewMutationRequest.delete(),
        ),
      );
      _applyBookingReviewsResult(bookingId, result);
      _removeExcursionReviewCache(reviewId);
      _actionState = ExcursionActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to delete excursion review';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> deleteGuideReview(String bookingId, String reviewId) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final result = await _excursionApi.saveBookingReviews(
        bookingId,
        const SaveBookingReviewsRequest(
          guideReview: ReviewMutationRequest.delete(),
        ),
      );
      _applyBookingReviewsResult(bookingId, result);
      _actionState = ExcursionActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to delete guide review';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadExcursionReviews({
    String? productId,
    String? landmarkId,
  }) async {
    final normalizedProductId = (productId ?? '').trim();
    final normalizedLandmarkId = (landmarkId ?? '').trim();
    if (normalizedProductId.isEmpty && normalizedLandmarkId.isEmpty) {
      return;
    }

    try {
      final page = await _excursionApi.getExcursionReviews(
        productId: normalizedProductId.isEmpty ? null : normalizedProductId,
        landmarkId: normalizedLandmarkId.isEmpty ? null : normalizedLandmarkId,
        limit: 20,
      );
      if (normalizedProductId.isNotEmpty) {
        _reviewsByProductId[normalizedProductId] = page.items;
      }
      if (normalizedLandmarkId.isNotEmpty) {
        _reviewsByLandmarkId[normalizedLandmarkId] = page.items;
      }
      notifyListeners();
    } catch (_) {
      // Reviews are supporting content; keep the primary detail page usable.
    }
  }

  Future<void> _reloadExcursionsAfterMutation({
    ExcursionVm? fallbackExcursion,
  }) async {
    try {
      _excursions = await _excursionApi.getExcursions();
      _listState = ExcursionListState.success;
      _listErrorMessage = null;
    } catch (_) {
      if (fallbackExcursion != null) {
        _upsertPublishedExcursion(fallbackExcursion);
      }
    }
  }

  Future<ExcursionVm?> _refreshProductAfterMutation(
    ExcursionVm changedExcursion, {
    String? preferredProductId,
    String? preferredLandmarkId,
  }) async {
    for (var attempt = 0; attempt < _marketplaceRefreshAttempts; attempt++) {
      await _reloadExcursionsAfterMutation(
        fallbackExcursion: attempt == 0 ? changedExcursion : null,
      );

      final productId = _resolveChangedProductId(
        changedExcursion,
        preferredProductId: preferredProductId,
        preferredLandmarkId: preferredLandmarkId,
      );
      if (productId == null) {
        if (attempt < _marketplaceRefreshAttempts - 1) {
          await Future<void>.delayed(
            Duration(
              milliseconds:
                  _marketplaceRefreshRetryDelay.inMilliseconds * (attempt + 1),
            ),
          );
        }
        continue;
      }

      try {
        final details = await _excursionApi.getExcursionById(productId);
        _excursionDetailsById[productId] = details;
        _detailErrorsByExcursionId.remove(productId);
        _upsertPublishedExcursion(details);
        if (_detailExcursionId == productId) {
          _selectedExcursion = details;
          _detailState = ExcursionDetailState.success;
          _detailErrorMessage = null;
        }
        return details;
      } catch (_) {
        final cachedProduct = _findCachedExcursion(productId);
        if (cachedProduct != null) {
          return cachedProduct;
        }
      }
      if (attempt < _marketplaceRefreshAttempts - 1) {
        await Future<void>.delayed(
          Duration(
            milliseconds:
                _marketplaceRefreshRetryDelay.inMilliseconds * (attempt + 1),
          ),
        );
      }
    }

    return changedExcursion;
  }

  String? _resolveChangedProductId(
    ExcursionVm changedExcursion, {
    String? preferredProductId,
    String? preferredLandmarkId,
  }) {
    final preferred = preferredProductId?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }

    final changedId = changedExcursion.id.trim();
    for (final excursion in _excursions) {
      if (excursion.id == changedId) return excursion.id;
    }

    final landmarkId =
        (preferredLandmarkId ?? changedExcursion.landmarkId ?? '').trim();
    if (landmarkId.isNotEmpty) {
      for (final excursion in _excursions) {
        if ((excursion.landmarkId ?? '').trim() == landmarkId) {
          return excursion.id;
        }
      }
    }

    for (final excursion in _excursions) {
      for (final offer in excursion.offers) {
        if ((offer.legacyExcursionId ?? '').trim() == changedId) {
          return excursion.id;
        }
      }
    }

    return null;
  }

  ExcursionVm? _findCachedExcursion(String excursionId) {
    for (final excursion in _excursions) {
      if (excursion.id == excursionId) return excursion;
    }
    return null;
  }

  void _upsertPublishedExcursion(ExcursionVm excursion) {
    final excursionId = excursion.id.trim();
    if (excursionId.isEmpty) return;

    final status = excursion.status.trim().toUpperCase();
    final visibility = excursion.visibility.trim().toUpperCase();
    if (status != 'PUBLISHED' || visibility != 'PUBLIC') {
      return;
    }
    if (excursion.publishedOffersCount <= 0 && excursion.offers.isEmpty) {
      return;
    }

    final nextExcursions = [..._excursions];
    final existingIndex = nextExcursions.indexWhere(
      (item) => item.id == excursionId,
    );
    if (existingIndex >= 0) {
      nextExcursions
        ..removeAt(existingIndex)
        ..insert(0, excursion);
    } else {
      nextExcursions.insert(0, excursion);
    }
    _excursions = List.unmodifiable(nextExcursions);
    _excursionDetailsById[excursionId] = excursion;
    _listState = ExcursionListState.success;
  }

  void _upsertGuideDashboardExcursion(ExcursionVm excursion) {
    final excursionId = excursion.id.trim();
    if (excursionId.isEmpty) return;

    final nextExcursions = [..._myGuideExcursions];
    final existingIndex = nextExcursions.indexWhere(
      (item) => item.id == excursionId,
    );
    if (existingIndex >= 0) {
      nextExcursions[existingIndex] = excursion;
    } else {
      nextExcursions.insert(0, excursion);
    }
    _myGuideExcursions = List.unmodifiable(nextExcursions);
  }

  void _upsertMyExcursionBooking(ExcursionBookingVm booking) {
    final bookingId = booking.id.trim();
    if (bookingId.isEmpty) return;

    final nextBookings = [..._myExcursionBookings];
    final existingIndex = nextBookings.indexWhere(
      (item) => item.id == bookingId,
    );
    if (existingIndex >= 0) {
      nextBookings[existingIndex] = booking;
    } else {
      nextBookings.insert(0, booking);
    }
    _myExcursionBookings = List.unmodifiable(nextBookings);
  }

  void _upsertBookingReview(String bookingId, ExcursionReviewVm review) {
    final normalizedBookingId = bookingId.trim();
    if (normalizedBookingId.isEmpty) return;

    _myExcursionBookings = _myExcursionBookings.map((booking) {
      if (booking.id != normalizedBookingId) return booking;
      return booking.copyWith(review: review);
    }).toList(growable: false);
  }

  ExcursionBookingVm? _applyBookingReviewsResult(
    String bookingId,
    BookingReviewsResultVm result,
  ) {
    final normalizedBookingId = bookingId.trim();
    if (normalizedBookingId.isEmpty) return null;

    ExcursionBookingVm? updatedBooking;
    _myExcursionBookings = _myExcursionBookings.map((booking) {
      if (booking.id != normalizedBookingId) return booking;
      updatedBooking = booking.copyWith(
        review: result.excursionReview,
        guideReview: result.guideReview,
      );
      return updatedBooking!;
    }).toList(growable: false);
    return updatedBooking;
  }

  void _upsertExcursionReviewCache(ExcursionReviewVm review) {
    final productId = review.productId.trim();
    if (productId.isNotEmpty) {
      final current = _reviewsByProductId[productId] ?? const [];
      _reviewsByProductId[productId] = _replaceOrPrependReview(current, review);
    }
    final landmarkId = review.landmarkId?.trim() ?? '';
    if (landmarkId.isNotEmpty) {
      final current = _reviewsByLandmarkId[landmarkId] ?? const [];
      _reviewsByLandmarkId[landmarkId] = _replaceOrPrependReview(
        current,
        review,
      );
    }
  }

  List<ExcursionReviewVm> _replaceOrPrependReview(
    List<ExcursionReviewVm> current,
    ExcursionReviewVm review,
  ) {
    final next = current.where((item) => item.id != review.id).toList();
    next.insert(0, review);
    return List.unmodifiable(next);
  }

  void _removeExcursionReviewCache(String reviewId) {
    final normalizedReviewId = reviewId.trim();
    if (normalizedReviewId.isEmpty) return;

    for (final entry in _reviewsByProductId.entries.toList()) {
      _reviewsByProductId[entry.key] = List.unmodifiable(
        entry.value.where((item) => item.id != normalizedReviewId),
      );
    }
    for (final entry in _reviewsByLandmarkId.entries.toList()) {
      _reviewsByLandmarkId[entry.key] = List.unmodifiable(
        entry.value.where((item) => item.id != normalizedReviewId),
      );
    }
  }
}
