import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/tour_api.dart';
import '../features/tours/models/create_tour_request.dart';
import '../features/tours/models/tour_vm.dart';

enum TourActionState { idle, loading, success, error }

enum TourListState { initial, loading, success, error }

enum TourDetailState { initial, loading, success, error }

class TourProvider extends ChangeNotifier {
  TourProvider({TourApi? tourApi}) : _tourApi = tourApi ?? TourApi();

  final TourApi _tourApi;

  TourListState _listState = TourListState.initial;
  List<TourVm> _tours = const [];
  String? _listErrorMessage;
  bool _isRefreshing = false;

  TourDetailState _detailState = TourDetailState.initial;
  String? _detailTourId;
  TourVm? _selectedTour;
  String? _detailErrorMessage;

  TourActionState _actionState = TourActionState.idle;
  String? _actionErrorMessage;
  TourVm? _lastCreatedTour;

  TourListState get listState => _listState;
  List<TourVm> get tours => _tours;
  String? get listErrorMessage => _listErrorMessage;
  bool get isRefreshing => _isRefreshing;

  TourDetailState get detailState => _detailState;
  TourVm? get selectedTour => _selectedTour;
  String? get detailErrorMessage => _detailErrorMessage;

  TourActionState get actionState => _actionState;
  String? get actionErrorMessage => _actionErrorMessage;
  TourVm? get lastCreatedTour => _lastCreatedTour;

  Future<void> loadTours({
    String? query,
    String? categorySlug,
    String? cityName,
  }) async {
    if (_listState == TourListState.loading || _isRefreshing) {
      return;
    }

    final hasCachedTours = _tours.isNotEmpty;
    if (hasCachedTours) {
      _isRefreshing = true;
    } else {
      _listState = TourListState.loading;
    }
    _listErrorMessage = null;
    notifyListeners();

    try {
      _tours = await _tourApi.getTours(
        query: query,
        categorySlug: categorySlug,
        cityName: cityName,
      );
      _listState = TourListState.success;
    } on DioException catch (e) {
      _listErrorMessage = DioErrorMapper.toMessage(e);
      if (!hasCachedTours) {
        _listState = TourListState.error;
      }
    } catch (_) {
      _listErrorMessage = 'Failed to load tours';
      if (!hasCachedTours) {
        _listState = TourListState.error;
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshTours({
    String? query,
    String? categorySlug,
    String? cityName,
  }) {
    return loadTours(
      query: query,
      categorySlug: categorySlug,
      cityName: cityName,
    );
  }

  Future<void> loadTourDetails(String tourId, {TourVm? initialTour}) async {
    final trimmedTourId = tourId.trim();
    if (trimmedTourId.isEmpty) {
      _detailState = TourDetailState.error;
      _detailErrorMessage = 'Invalid tour id';
      notifyListeners();
      return;
    }

    final cachedTour = initialTour ?? _findCachedTour(trimmedTourId);
    final hasCachedTour = cachedTour != null;

    _detailTourId = trimmedTourId;
    _detailErrorMessage = null;
    if (hasCachedTour) {
      _selectedTour = cachedTour;
      _detailState = TourDetailState.success;
    } else {
      _selectedTour = null;
      _detailState = TourDetailState.loading;
    }
    notifyListeners();

    try {
      final tour = await _tourApi.getTourById(trimmedTourId);
      if (_detailTourId != trimmedTourId) return;

      _selectedTour = tour;
      _detailState = TourDetailState.success;
    } on DioException catch (e) {
      if (_detailTourId != trimmedTourId) return;

      _detailErrorMessage = DioErrorMapper.toMessage(e);
      if (!hasCachedTour) {
        _detailState = TourDetailState.error;
      }
    } catch (_) {
      if (_detailTourId != trimmedTourId) return;

      _detailErrorMessage = 'Failed to load tour';
      if (!hasCachedTour) {
        _detailState = TourDetailState.error;
      }
    } finally {
      if (_detailTourId == trimmedTourId) {
        notifyListeners();
      }
    }
  }

  void resetActionState() {
    _actionState = TourActionState.idle;
    _actionErrorMessage = null;
    notifyListeners();
  }

  Future<TourVm?> createAndPublishTour(CreateTourRequest request) async {
    _actionState = TourActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final created = await _tourApi.createTour(request);
      final published = await _tourApi.publishTour(created.id);
      _lastCreatedTour = published;
      _upsertPublishedTour(published);
      _actionState = TourActionState.success;
      return published;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = TourActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to create tour';
      _actionState = TourActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  TourVm? _findCachedTour(String tourId) {
    for (final tour in _tours) {
      if (tour.id == tourId) return tour;
    }
    return null;
  }

  void _upsertPublishedTour(TourVm tour) {
    final tourId = tour.id.trim();
    if (tourId.isEmpty) return;

    final status = tour.status.trim().toUpperCase();
    final visibility = tour.visibility.trim().toUpperCase();
    if (status != 'PUBLISHED' || visibility != 'PUBLIC') {
      return;
    }

    final nextTours = [..._tours];
    final existingIndex = nextTours.indexWhere((item) => item.id == tourId);
    if (existingIndex >= 0) {
      nextTours
        ..removeAt(existingIndex)
        ..insert(0, tour);
    } else {
      nextTours.insert(0, tour);
    }
    _tours = List.unmodifiable(nextTours);
    _listState = TourListState.success;
  }
}
