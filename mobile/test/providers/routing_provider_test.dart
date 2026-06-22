import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/routing_api.dart';
import 'package:inflap/features/routing/models/routing_models.dart';
import 'package:inflap/providers/routing_provider.dart';

void main() {
  test('buildRoute updates loading and success state', () async {
    final provider = RoutingProvider(
      routingApi: _FakeRoutingApi(
        routeResponse: const RouteResponseVm(
          provider: 'valhalla',
          mode: RouteMode.walking,
          profile: RouteProfile.touristWalk,
          distanceMeters: 1200,
          durationSeconds: 900,
          geometry: RouteGeometryVm(encoding: 'polyline6', polyline: 'encoded'),
        ),
      ),
    );

    final states = <RoutingState>[];
    provider.addListener(() => states.add(provider.state));

    final response = await provider.buildRoute(
      RouteRequestVm(
        profile: RouteProfile.touristWalk,
        points: const [
          RoutePointVm(latitude: 43.238949, longitude: 76.889709),
          RoutePointVm(latitude: 43.255058, longitude: 76.912628),
        ],
      ),
    );

    expect(response?.provider, 'valhalla');
    expect(provider.route?.durationSeconds, 900);
    expect(provider.errorMessage, isNull);
    expect(states, [RoutingState.loading, RoutingState.success]);
  });

  test('buildRoute maps Dio errors to user-facing provider error', () async {
    final provider = RoutingProvider(
      routingApi: _FakeRoutingApi(
        routeError: DioException(
          requestOptions: RequestOptions(path: '/routing/routes'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/routing/routes'),
            statusCode: 503,
            data: const {'message': 'Routing is temporarily unavailable.'},
          ),
        ),
      ),
    );

    final response = await provider.buildRoute(
      RouteRequestVm(
        profile: RouteProfile.transit,
        points: const [
          RoutePointVm(latitude: 43.238949, longitude: 76.889709),
          RoutePointVm(latitude: 43.255058, longitude: 76.912628),
        ],
      ),
    );

    expect(response, isNull);
    expect(provider.state, RoutingState.error);
    expect(provider.errorMessage, 'Routing is temporarily unavailable.');
  });

  test(
    'buildRoute converts hung routing requests into an error state',
    () async {
      final provider = RoutingProvider(
        routingApi: _FakeRoutingApi(hangRoute: true),
        requestTimeout: const Duration(milliseconds: 10),
      );

      final response = await provider.buildRoute(
        RouteRequestVm(
          profile: RouteProfile.touristWalk,
          points: const [
            RoutePointVm(latitude: 43.238949, longitude: 76.889709),
            RoutePointVm(latitude: 43.255058, longitude: 76.912628),
          ],
        ),
      );

      expect(response, isNull);
      expect(provider.state, RoutingState.error);
      expect(provider.errorMessage, 'Routing request timed out');
    },
  );

  test('getEta updates loading and success state', () async {
    final provider = RoutingProvider(
      routingApi: _FakeRoutingApi(
        etaResponse: const EtaResponseVm(
          provider: 'valhalla',
          mode: RouteMode.walking,
          profile: RouteProfile.touristWalk,
          distanceMeters: 950,
          durationSeconds: 720,
        ),
      ),
    );

    final states = <RoutingState>[];
    provider.addListener(() => states.add(provider.state));

    final response = await provider.getEta(
      EtaRequestVm(
        profile: RouteProfile.touristWalk,
        origin: const RoutePointVm(latitude: 43.238949, longitude: 76.889709),
        destination: const RoutePointVm(
          latitude: 43.255058,
          longitude: 76.912628,
        ),
      ),
    );

    expect(response?.durationSeconds, 720);
    expect(provider.eta?.distanceMeters, 950);
    expect(provider.errorMessage, isNull);
    expect(states, [RoutingState.loading, RoutingState.success]);
  });

  test('getEta converts hung routing requests into an error state', () async {
    final provider = RoutingProvider(
      routingApi: _FakeRoutingApi(hangEta: true),
      requestTimeout: const Duration(milliseconds: 10),
    );

    final response = await provider.getEta(
      EtaRequestVm(
        profile: RouteProfile.touristWalk,
        origin: const RoutePointVm(latitude: 43.238949, longitude: 76.889709),
        destination: const RoutePointVm(
          latitude: 43.255058,
          longitude: 76.912628,
        ),
      ),
    );

    expect(response, isNull);
    expect(provider.state, RoutingState.error);
    expect(provider.errorMessage, 'Routing request timed out');
  });

  test('optimizeItinerary updates loading and success state', () async {
    final provider = RoutingProvider(
      routingApi: _FakeRoutingApi(
        itineraryResponse: ItineraryOptimizationResponseVm(
          provider: 'valhalla',
          orderedStops: const [
            RoutePointVm(latitude: 43.255058, longitude: 76.912628),
            RoutePointVm(latitude: 43.238949, longitude: 76.889709),
          ],
          route: const RouteResponseVm(
            provider: 'valhalla',
            mode: RouteMode.walking,
            profile: RouteProfile.dayPlan,
            distanceMeters: 1800,
            durationSeconds: 1600,
            geometry: RouteGeometryVm(encoding: 'polyline6', polyline: '??AA'),
          ),
          durationSeconds: 1600,
          distanceMeters: 1800,
        ),
      ),
    );

    final states = <RoutingState>[];
    provider.addListener(() => states.add(provider.state));

    final response = await provider.optimizeItinerary(
      ItineraryOptimizationRequestVm(
        profile: RouteProfile.dayPlan,
        stops: const [
          RoutePointVm(latitude: 43.238949, longitude: 76.889709),
          RoutePointVm(latitude: 43.255058, longitude: 76.912628),
        ],
      ),
    );

    expect(response?.provider, 'valhalla');
    expect(provider.optimizedItinerary?.orderedStops, hasLength(2));
    expect(provider.errorMessage, isNull);
    expect(states, [RoutingState.loading, RoutingState.success]);
  });
}

class _FakeRoutingApi extends RoutingApi {
  _FakeRoutingApi({
    this.routeResponse,
    this.etaResponse,
    this.itineraryResponse,
    this.routeError,
    this.hangRoute = false,
    this.hangEta = false,
  });

  final RouteResponseVm? routeResponse;
  final EtaResponseVm? etaResponse;
  final ItineraryOptimizationResponseVm? itineraryResponse;
  final Object? routeError;
  final bool hangRoute;
  final bool hangEta;

  @override
  Future<RouteResponseVm> buildRoute(RouteRequestVm request) async {
    if (hangRoute) {
      return Completer<RouteResponseVm>().future;
    }
    final error = routeError;
    if (error != null) {
      throw error;
    }
    return routeResponse!;
  }

  @override
  Future<EtaResponseVm> getEta(EtaRequestVm request) async {
    if (hangEta) {
      return Completer<EtaResponseVm>().future;
    }
    final error = routeError;
    if (error != null) {
      throw error;
    }
    return etaResponse!;
  }

  @override
  Future<ItineraryOptimizationResponseVm> optimizeItinerary(
    ItineraryOptimizationRequestVm request,
  ) async {
    final error = routeError;
    if (error != null) {
      throw error;
    }
    return itineraryResponse!;
  }
}
