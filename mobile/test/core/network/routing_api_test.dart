import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/routing_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/routing/models/routing_models.dart';

void main() {
  test('buildRoute posts through Inflap gateway routing endpoint', () async {
    final adapter = _RoutingAdapter({
      'provider': 'valhalla',
      'mode': 'walking',
      'profile': 'tourist_walk',
      'distanceMeters': 1200,
      'durationSeconds': 900,
      'geometry': {'encoding': 'polyline6', 'polyline': 'encoded'},
    });
    final api = RoutingApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final response = await api.buildRoute(
      RouteRequestVm(
        profile: RouteProfile.touristWalk,
        points: const [
          RoutePointVm(latitude: 43.238949, longitude: 76.889709),
          RoutePointVm(latitude: 43.255058, longitude: 76.912628),
        ],
      ),
    );

    expect(response.provider, 'valhalla');
    expect(adapter.requestPath, '/api/v1/routing/routes');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestPayload['profile'], 'tourist_walk');
  });

  test('getRouteProfiles reads routing profiles endpoint', () async {
    final adapter = _RoutingAdapter([
      {
        'id': 'tourist_walk',
        'mode': 'walking',
        'label': 'Tourist walk',
        'description': 'Sightseeing',
      },
    ]);
    final api = RoutingApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final profiles = await api.getRouteProfiles();

    expect(profiles.single.id, RouteProfile.touristWalk);
    expect(adapter.requestPath, '/api/v1/routing/route-profiles');
    expect(adapter.method, 'GET');
    expect(adapter.requiresAuth, isTrue);
  });

  test('getEta posts ETA request through routing endpoint', () async {
    final adapter = _RoutingAdapter({
      'provider': 'valhalla',
      'mode': 'walking',
      'profile': 'tourist_walk',
      'distanceMeters': 950,
      'durationSeconds': 720,
    });
    final api = _routingApi(adapter);

    final response = await api.getEta(
      EtaRequestVm(
        profile: RouteProfile.touristWalk,
        origin: const RoutePointVm(latitude: 43.238949, longitude: 76.889709),
        destination: const RoutePointVm(
          latitude: 43.255058,
          longitude: 76.912628,
        ),
      ),
    );

    expect(response.durationSeconds, 720);
    expect(adapter.requestPath, '/api/v1/routing/eta');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestPayload['profile'], 'tourist_walk');
  });

  test('getMatrix posts matrix request through routing endpoint', () async {
    final adapter = _RoutingAdapter({
      'provider': 'osrm',
      'rows': [
        {
          'cells': [
            {'distanceMeters': 1200, 'durationSeconds': 600, 'reachable': true},
          ],
        },
      ],
    });
    final api = _routingApi(adapter);

    final response = await api.getMatrix(
      MatrixRequestVm(
        profile: RouteProfile.carStandard,
        origins: const [
          RoutePointVm(latitude: 43.238949, longitude: 76.889709),
        ],
        destinations: const [
          RoutePointVm(latitude: 43.255058, longitude: 76.912628),
        ],
      ),
    );

    expect(response.rows.single.cells.single.reachable, isTrue);
    expect(adapter.requestPath, '/api/v1/routing/matrix');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestPayload['profile'], 'car_standard');
  });

  test(
    'buildIsochrone posts isochrone request through routing endpoint',
    () async {
      final adapter = _RoutingAdapter({
        'provider': 'valhalla',
        'features': [
          {
            'type': 'Feature',
            'properties': {'contour': 15},
          },
        ],
      });
      final api = _routingApi(adapter);

      final response = await api.buildIsochrone(
        IsochroneRequestVm(
          profile: RouteProfile.touristWalk,
          origin: const RoutePointVm(latitude: 43.238949, longitude: 76.889709),
          minutes: const [15],
        ),
      );

      expect(response.features.single['type'], 'Feature');
      expect(adapter.requestPath, '/api/v1/routing/isochrones');
      expect(adapter.method, 'POST');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.requestPayload['minutes'], [15]);
    },
  );

  test(
    'optimizeItinerary posts day plan request through routing endpoint',
    () async {
      final adapter = _RoutingAdapter({
        'provider': 'valhalla',
        'orderedStops': [
          {'latitude': 43.255058, 'longitude': 76.912628},
        ],
        'durationSeconds': 900,
        'distanceMeters': 1234,
        'route': {
          'provider': 'valhalla',
          'mode': 'walking',
          'profile': 'day_plan',
          'distanceMeters': 1234,
          'durationSeconds': 900,
          'geometry': {'encoding': 'polyline6', 'polyline': '??AA'},
        },
      });
      final api = _routingApi(adapter);

      final response = await api.optimizeItinerary(
        ItineraryOptimizationRequestVm(
          profile: RouteProfile.dayPlan,
          stops: const [
            RoutePointVm(latitude: 43.255058, longitude: 76.912628),
          ],
        ),
      );

      expect(response.route.profile, RouteProfile.dayPlan);
      expect(adapter.requestPath, '/api/v1/routing/itineraries/optimize');
      expect(adapter.method, 'POST');
      expect(adapter.requiresAuth, isTrue);
    },
  );

  test('mapMatch posts trace request through routing endpoint', () async {
    final adapter = _RoutingAdapter({
      'provider': 'valhalla',
      'route': {
        'provider': 'valhalla',
        'mode': 'walking',
        'profile': 'tourist_walk',
        'distanceMeters': 50,
        'durationSeconds': 42,
        'geometry': {'encoding': 'polyline6', 'polyline': '??AA'},
      },
    });
    final api = _routingApi(adapter);

    final response = await api.mapMatch(
      MapMatchRequestVm(
        profile: RouteProfile.touristWalk,
        trace: const [
          RoutePointVm(latitude: 43.238949, longitude: 76.889709),
          RoutePointVm(latitude: 43.255058, longitude: 76.912628),
        ],
      ),
    );

    expect(response.route.durationSeconds, 42);
    expect(adapter.requestPath, '/api/v1/routing/map-match');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
  });
}

RoutingApi _routingApi(_RoutingAdapter adapter) {
  return RoutingApi(
    apiClient: ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _FakeSecureStorage(),
    ),
  );
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.payload);

  final Object payload;
  String? requestPath;
  String? method;
  bool? requiresAuth;
  Map<String, dynamic> requestPayload = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
    method = options.method;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = chunks.expand((chunk) => chunk).toList(growable: false);
      if (bytes.isNotEmpty) {
        requestPayload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      }
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
