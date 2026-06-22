import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/routing_api.dart';
import '../features/routing/models/routing_models.dart';

enum RoutingState { initial, loading, success, error }

class RoutingProvider extends ChangeNotifier {
  RoutingProvider({
    RoutingApi? routingApi,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _routingApi = routingApi ?? RoutingApi();

  final RoutingApi _routingApi;
  final Duration requestTimeout;

  RoutingState _state = RoutingState.initial;
  String? _errorMessage;
  RouteResponseVm? _route;
  EtaResponseVm? _eta;
  ItineraryOptimizationResponseVm? _optimizedItinerary;
  List<RouteProfileInfoVm> _profiles = const [];

  RoutingState get state => _state;
  String? get errorMessage => _errorMessage;
  RouteResponseVm? get route => _route;
  EtaResponseVm? get eta => _eta;
  ItineraryOptimizationResponseVm? get optimizedItinerary =>
      _optimizedItinerary;
  List<RouteProfileInfoVm> get profiles => _profiles;

  Future<RouteResponseVm?> buildRoute(RouteRequestVm request) async {
    _state = RoutingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _routingApi
          .buildRoute(request)
          .timeout(requestTimeout);
      _route = response;
      _state = RoutingState.success;
      notifyListeners();
      return response;
    } on TimeoutException {
      _errorMessage = 'Routing request timed out';
      _state = RoutingState.error;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = RoutingState.error;
    } catch (_) {
      _errorMessage = 'Failed to build route';
      _state = RoutingState.error;
    }

    notifyListeners();
    return null;
  }

  Future<ItineraryOptimizationResponseVm?> optimizeItinerary(
    ItineraryOptimizationRequestVm request,
  ) async {
    _state = RoutingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _routingApi
          .optimizeItinerary(request)
          .timeout(requestTimeout);
      _optimizedItinerary = response;
      _state = RoutingState.success;
      notifyListeners();
      return response;
    } on TimeoutException {
      _errorMessage = 'Routing request timed out';
      _state = RoutingState.error;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = RoutingState.error;
    } catch (_) {
      _errorMessage = 'Failed to optimize itinerary';
      _state = RoutingState.error;
    }

    notifyListeners();
    return null;
  }

  Future<EtaResponseVm?> getEta(EtaRequestVm request) async {
    _state = RoutingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _routingApi
          .getEta(request)
          .timeout(requestTimeout);
      _eta = response;
      _state = RoutingState.success;
      notifyListeners();
      return response;
    } on TimeoutException {
      _errorMessage = 'Routing request timed out';
      _state = RoutingState.error;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = RoutingState.error;
    } catch (_) {
      _errorMessage = 'Failed to calculate ETA';
      _state = RoutingState.error;
    }

    notifyListeners();
    return null;
  }

  Future<void> loadRouteProfiles({bool force = false}) async {
    if (!force && _profiles.isNotEmpty) {
      return;
    }

    _state = RoutingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profiles = await _routingApi.getRouteProfiles().timeout(requestTimeout);
      _state = RoutingState.success;
    } on TimeoutException {
      _errorMessage = 'Routing request timed out';
      _state = RoutingState.error;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = RoutingState.error;
    } catch (_) {
      _errorMessage = 'Failed to load route profiles';
      _state = RoutingState.error;
    }

    notifyListeners();
  }

  void clearRoute() {
    _route = null;
    _eta = null;
    _optimizedItinerary = null;
    if (_state != RoutingState.loading) {
      _state = RoutingState.initial;
    }
    _errorMessage = null;
    notifyListeners();
  }
}
