import 'package:dio/dio.dart';

import '../../features/user_routes/models/user_route_models.dart';
import 'api_client.dart';

class UserRoutesApi {
  UserRoutesApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<UserRouteVm>> listPublicRoutes({
    String? cityCode,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/user-routes',
      queryParameters: _query({
        'visibility': 'public',
        'cityCode': cityCode,
        'limit': limit,
        'offset': offset,
      }),
      options: Options(
        extra: const {'requiresAuth': false, 'optionalAuth': true},
      ),
    );
    return _parseRoutePage(response.data);
  }

  Future<List<UserRouteVm>> listMyRoutes({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/user-routes',
      queryParameters: _query({
        'scope': 'my',
        'limit': limit,
        'offset': offset,
      }),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return _parseRoutePage(response.data);
  }

  Future<List<UserRouteVm>> listSavedRoutes({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/user-routes',
      queryParameters: _query({
        'scope': 'saved',
        'limit': limit,
        'offset': offset,
      }),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return _parseRoutePage(response.data);
  }

  Future<UserRouteVm> getRoute(String routeId) async {
    final response = await _apiClient.dio.get(
      '/user-routes/${Uri.encodeComponent(routeId)}',
      options: Options(
        extra: const {'requiresAuth': false, 'optionalAuth': true},
      ),
    );
    return UserRouteVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<UserRouteVm> createRoute(CreateUserRouteRequestVm request) async {
    final response = await _apiClient.dio.post(
      '/user-routes',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return UserRouteVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<UserRouteVm> updateRoute(
    String routeId,
    UpdateUserRouteRequestVm request,
  ) async {
    final response = await _apiClient.dio.patch(
      '/user-routes/${Uri.encodeComponent(routeId)}',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return UserRouteVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<UserRouteVm> saveRoute(String routeId) async {
    final response = await _apiClient.dio.post(
      '/user-routes/${Uri.encodeComponent(routeId)}/save',
      options: Options(extra: const {'requiresAuth': true}),
    );
    return UserRouteVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<UserRouteVm> unsaveRoute(String routeId) async {
    final response = await _apiClient.dio.delete(
      '/user-routes/${Uri.encodeComponent(routeId)}/save',
      options: Options(extra: const {'requiresAuth': true}),
    );
    return UserRouteVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<UserRouteVm> copyRoute(String routeId) async {
    final response = await _apiClient.dio.post(
      '/user-routes/${Uri.encodeComponent(routeId)}/copy',
      options: Options(extra: const {'requiresAuth': true}),
    );
    return UserRouteVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  List<UserRouteVm> _parseRoutePage(Object? data) {
    final page = data as Map<String, dynamic>? ?? const <String, dynamic>{};
    final items = page['items'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map>()
        .map((item) => UserRouteVm.fromJson(_dynamicMap(item)))
        .toList(growable: false);
  }

  Map<String, Object?> _query(Map<String, Object?> input) {
    final result = <String, Object?>{};
    for (final entry in input.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      result[entry.key] = value;
    }
    return result;
  }
}

Map<String, dynamic> _dynamicMap(Map<Object?, Object?> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}
