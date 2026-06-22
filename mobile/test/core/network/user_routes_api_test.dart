import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/user_routes_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/routing/models/routing_models.dart';
import 'package:inflap/features/user_routes/models/user_route_models.dart';

void main() {
  test(
    'listPublicRoutes reads public user routes without required auth',
    () async {
      final adapter = _UserRoutesAdapter({
        'items': [_routePayload(savedByMe: false)],
      });
      final api = _api(adapter);

      final routes = await api.listPublicRoutes(cityCode: 'almaty');

      expect(routes.single.id, 'route_1');
      expect(adapter.requestPath, '/api/v1/user-routes');
      expect(adapter.query['cityCode'], 'almaty');
      expect(adapter.query['visibility'], 'public');
      expect(adapter.method, 'GET');
      expect(adapter.requiresAuth, isFalse);
      expect(adapter.optionalAuth, isTrue);
    },
  );

  test('createRoute posts authenticated user route content', () async {
    final adapter = _UserRoutesAdapter(_routePayload(savedByMe: false));
    final api = _api(adapter);

    final route = await api.createRoute(
      CreateUserRouteRequestVm(
        title: 'City walk',
        visibility: UserRouteVisibility.public,
        profile: RouteProfile.touristWalk,
        points: const [
          UserRoutePointVm(latitude: 43.238949, longitude: 76.889709),
          UserRoutePointVm(latitude: 43.239931, longitude: 76.912345),
        ],
        snapshot: const UserRouteSnapshotVm(
          provider: 'valhalla',
          mode: RouteMode.walking,
          profile: RouteProfile.touristWalk,
          distanceMeters: 1800,
          durationSeconds: 1320,
          encodedPolyline: 'encoded-route',
        ),
      ),
    );

    expect(route.title, 'Алматы: кофе и парк');
    expect(adapter.requestPath, '/api/v1/user-routes');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestPayload['visibility'], 'public');
  });

  test('save and copy route use authenticated action endpoints', () async {
    final adapter = _UserRoutesAdapter(_routePayload(savedByMe: true));
    final api = _api(adapter);

    final saved = await api.saveRoute('route_1');
    expect(saved.savedByMe, isTrue);
    expect(adapter.requestPath, '/api/v1/user-routes/route_1/save');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);

    final copied = await api.copyRoute('route_1');
    expect(copied.id, 'route_1');
    expect(adapter.requestPath, '/api/v1/user-routes/route_1/copy');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
  });

  test('updateRoute patches authenticated route metadata', () async {
    final adapter = _UserRoutesAdapter(_routePayload(savedByMe: false));
    final api = _api(adapter);

    final route = await api.updateRoute(
      'route_1',
      const UpdateUserRouteRequestVm(
        title: 'Public coffee walk',
        visibility: UserRouteVisibility.unlisted,
      ),
    );

    expect(route.id, 'route_1');
    expect(adapter.requestPath, '/api/v1/user-routes/route_1');
    expect(adapter.method, 'PATCH');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestPayload, {
      'title': 'Public coffee walk',
      'visibility': 'unlisted',
    });
  });
}

UserRoutesApi _api(_UserRoutesAdapter adapter) {
  return UserRoutesApi(
    apiClient: ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _FakeSecureStorage(),
    ),
  );
}

Map<String, Object?> _routePayload({required bool savedByMe}) {
  return {
    'id': 'route_1',
    'ownerUserId': 'user-1',
    'title': 'Алматы: кофе и парк',
    'visibility': 'public',
    'profile': 'tourist_walk',
    'points': [
      {'latitude': 43.238949, 'longitude': 76.889709},
      {'latitude': 43.239931, 'longitude': 76.912345},
    ],
    'snapshot': {
      'provider': 'valhalla',
      'mode': 'walking',
      'profile': 'tourist_walk',
      'distanceMeters': 1800,
      'durationSeconds': 1320,
      'encodedPolyline': 'encoded-route',
    },
    'stats': {
      'savesCount': savedByMe ? 1 : 0,
      'copiesCount': 0,
      'viewsCount': 0,
    },
    'savedByMe': savedByMe,
  };
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _UserRoutesAdapter implements HttpClientAdapter {
  _UserRoutesAdapter(this.payload);

  final Object payload;
  String? requestPath;
  String? method;
  bool? requiresAuth;
  bool? optionalAuth;
  Map<String, dynamic> requestPayload = const {};
  Map<String, String> query = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
    method = options.method;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    optionalAuth = options.extra['optionalAuth'] as bool?;
    query = options.uri.queryParameters;
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
