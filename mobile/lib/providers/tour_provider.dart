import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/tour_api.dart';
import '../features/tours/models/create_tour_request.dart';
import '../features/tours/models/tour_vm.dart';

enum TourActionState { idle, loading, success, error }

class TourProvider extends ChangeNotifier {
  TourProvider({TourApi? tourApi}) : _tourApi = tourApi ?? TourApi();

  final TourApi _tourApi;

  TourActionState _actionState = TourActionState.idle;
  String? _actionErrorMessage;
  TourVm? _lastCreatedTour;

  TourActionState get actionState => _actionState;
  String? get actionErrorMessage => _actionErrorMessage;
  TourVm? get lastCreatedTour => _lastCreatedTour;

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
