import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/user_routes_api.dart';
import '../features/routing/models/routing_models.dart';
import '../features/user_routes/models/user_route_models.dart';

enum UserRoutesState { initial, loading, success, error }

class UserRoutesProvider extends ChangeNotifier {
  UserRoutesProvider({
    UserRoutesApi? userRoutesApi,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _userRoutesApi = userRoutesApi ?? UserRoutesApi();

  final UserRoutesApi _userRoutesApi;
  final Duration requestTimeout;

  UserRoutesState _state = UserRoutesState.initial;
  String? _errorMessage;
  List<UserRouteVm> _publicRoutes = const [];
  List<UserRouteVm> _myRoutes = const [];
  List<UserRouteVm> _savedRoutes = const [];
  UserRouteVm? _selectedRoute;

  UserRoutesState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserRouteVm> get publicRoutes => _publicRoutes;
  List<UserRouteVm> get myRoutes => _myRoutes;
  List<UserRouteVm> get savedRoutes => _savedRoutes;
  UserRouteVm? get selectedRoute => _selectedRoute;

  void setSelectedRoute(UserRouteVm? route) {
    _selectedRoute = route;
    notifyListeners();
  }

  Future<void> loadPublicRoutes({
    String? cityCode,
    int limit = 20,
    int offset = 0,
  }) async {
    await _loadList(
      loader: () => _userRoutesApi
          .listPublicRoutes(cityCode: cityCode, limit: limit, offset: offset)
          .timeout(requestTimeout),
      assign: (routes) => _publicRoutes = routes,
    );
  }

  Future<void> loadMyRoutes({int limit = 20, int offset = 0}) async {
    await _loadList(
      loader: () => _userRoutesApi
          .listMyRoutes(limit: limit, offset: offset)
          .timeout(requestTimeout),
      assign: (routes) => _myRoutes = routes,
    );
  }

  Future<void> loadSavedRoutes({int limit = 20, int offset = 0}) async {
    await _loadList(
      loader: () => _userRoutesApi
          .listSavedRoutes(limit: limit, offset: offset)
          .timeout(requestTimeout),
      assign: (routes) => _savedRoutes = routes,
    );
  }

  Future<UserRouteVm?> getRoute(String routeId) async {
    return _runRouteAction(
      action: () => _userRoutesApi.getRoute(routeId).timeout(requestTimeout),
      updateSelected: true,
    );
  }

  Future<UserRouteVm?> createRoute(CreateUserRouteRequestVm request) async {
    return _runRouteAction(
      action: () => _userRoutesApi.createRoute(request).timeout(requestTimeout),
      addToMyRoutes: true,
      updateSelected: true,
    );
  }

  Future<UserRouteVm?> createFromBuiltRoute({
    required String title,
    required RouteResponseVm route,
    required List<RoutePointVm> points,
    String? description,
    UserRouteVisibility visibility = UserRouteVisibility.private,
    String? cityCode,
    List<String> tags = const [],
  }) async {
    return createRoute(
      CreateUserRouteRequestVm.fromBuiltRoute(
        title: title,
        route: route,
        points: points,
        description: description,
        visibility: visibility,
        cityCode: cityCode,
        tags: tags,
      ),
    );
  }

  Future<UserRouteVm?> updateRoute(
    String routeId,
    UpdateUserRouteRequestVm request,
  ) async {
    return _runRouteAction(
      action: () =>
          _userRoutesApi.updateRoute(routeId, request).timeout(requestTimeout),
      addToMyRoutes: true,
      updateSelected: true,
    );
  }

  Future<UserRouteVm?> saveRoute(String routeId) async {
    return _runRouteAction(
      action: () => _userRoutesApi.saveRoute(routeId).timeout(requestTimeout),
      updateSelected: true,
    );
  }

  Future<UserRouteVm?> unsaveRoute(String routeId) async {
    return _runRouteAction(
      action: () => _userRoutesApi.unsaveRoute(routeId).timeout(requestTimeout),
      updateSelected: true,
    );
  }

  Future<UserRouteVm?> copyRoute(String routeId) async {
    return _runRouteAction(
      action: () => _userRoutesApi.copyRoute(routeId).timeout(requestTimeout),
      addToMyRoutes: true,
      updateSelected: true,
    );
  }

  Future<void> _loadList({
    required Future<List<UserRouteVm>> Function() loader,
    required void Function(List<UserRouteVm> routes) assign,
  }) async {
    _state = UserRoutesState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      assign(await loader());
      _state = UserRoutesState.success;
    } on TimeoutException {
      _errorMessage = 'User routes request timed out';
      _state = UserRoutesState.error;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = UserRoutesState.error;
    } catch (_) {
      _errorMessage = 'Failed to load user routes';
      _state = UserRoutesState.error;
    }

    notifyListeners();
  }

  Future<UserRouteVm?> _runRouteAction({
    required Future<UserRouteVm> Function() action,
    bool addToMyRoutes = false,
    bool updateSelected = false,
  }) async {
    _state = UserRoutesState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final route = await action();
      if (addToMyRoutes) {
        _myRoutes = _upsertRoute(_myRoutes, route);
      }
      _publicRoutes = _upsertRoute(_publicRoutes, route, onlyIfPresent: true);
      _savedRoutes = route.savedByMe
          ? _upsertRoute(_savedRoutes, route)
          : _removeRoute(_savedRoutes, route.id);
      if (updateSelected && _selectedRoute?.id == route.id ||
          updateSelected && _selectedRoute == null) {
        _selectedRoute = route;
      }
      _state = UserRoutesState.success;
      notifyListeners();
      return route;
    } on TimeoutException {
      _errorMessage = 'User routes request timed out';
      _state = UserRoutesState.error;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = UserRoutesState.error;
    } catch (_) {
      _errorMessage = 'Failed to update user route';
      _state = UserRoutesState.error;
    }

    notifyListeners();
    return null;
  }

  List<UserRouteVm> _upsertRoute(
    List<UserRouteVm> routes,
    UserRouteVm route, {
    bool onlyIfPresent = false,
  }) {
    final index = routes.indexWhere((item) => item.id == route.id);
    if (index < 0) {
      return onlyIfPresent ? routes : [route, ...routes];
    }
    final updated = List<UserRouteVm>.of(routes);
    updated[index] = route;
    return List<UserRouteVm>.unmodifiable(updated);
  }

  List<UserRouteVm> _removeRoute(List<UserRouteVm> routes, String routeId) {
    return List<UserRouteVm>.unmodifiable(
      routes.where((route) => route.id != routeId),
    );
  }
}
