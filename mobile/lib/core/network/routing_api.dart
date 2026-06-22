import 'package:dio/dio.dart';

import '../../features/routing/models/routing_models.dart';
import 'api_client.dart';

class RoutingApi {
  RoutingApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<RouteProfileInfoVm>> getRouteProfiles() async {
    final response = await _apiClient.dio.get(
      '/routing/route-profiles',
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    final items = data is List ? data : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(RouteProfileInfoVm.fromJson)
        .toList(growable: false);
  }

  Future<RouteResponseVm> buildRoute(RouteRequestVm request) async {
    final response = await _apiClient.dio.post(
      '/routing/routes',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return RouteResponseVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<EtaResponseVm> getEta(EtaRequestVm request) async {
    final response = await _apiClient.dio.post(
      '/routing/eta',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return EtaResponseVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<MatrixResponseVm> getMatrix(MatrixRequestVm request) async {
    final response = await _apiClient.dio.post(
      '/routing/matrix',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return MatrixResponseVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<IsochroneResponseVm> buildIsochrone(IsochroneRequestVm request) async {
    final response = await _apiClient.dio.post(
      '/routing/isochrones',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return IsochroneResponseVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<ItineraryOptimizationResponseVm> optimizeItinerary(
    ItineraryOptimizationRequestVm request,
  ) async {
    final response = await _apiClient.dio.post(
      '/routing/itineraries/optimize',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return ItineraryOptimizationResponseVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Future<MapMatchResponseVm> mapMatch(MapMatchRequestVm request) async {
    final response = await _apiClient.dio.post(
      '/routing/map-match',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );
    return MapMatchResponseVm.fromJson(
      response.data as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }
}
