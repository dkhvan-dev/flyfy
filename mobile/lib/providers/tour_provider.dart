import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/tour_api.dart';
import '../features/tours/models/create_tour_request.dart';
import '../features/tours/models/tour_vm.dart';

enum TourActionState { idle, loading, success, error }

enum TourListState { initial, loading, success, error }

class TourProvider extends ChangeNotifier {
  TourProvider({TourApi? tourApi}) : _tourApi = tourApi ?? TourApi();

  final TourApi _tourApi;

  TourListState _listState = TourListState.initial;
  List<TourVm> _tours = const [];
  String? _listErrorMessage;
  bool _isRefreshing = false;

  TourActionState _actionState = TourActionState.idle;
  String? _actionErrorMessage;
  TourVm? _lastCreatedTour;

  TourListState get listState => _listState;
  List<TourVm> get tours => _tours;
  String? get listErrorMessage => _listErrorMessage;
  bool get isRefreshing => _isRefreshing;

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
}
