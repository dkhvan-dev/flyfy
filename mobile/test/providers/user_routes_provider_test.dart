import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/user_routes_api.dart';
import 'package:inflap/features/routing/models/routing_models.dart';
import 'package:inflap/features/user_routes/models/user_route_models.dart';
import 'package:inflap/providers/user_routes_provider.dart';

void main() {
  test('loadPublicRoutes updates loading and success state', () async {
    final provider = UserRoutesProvider(
      userRoutesApi: _FakeUserRoutesApi(
        publicRoutes: [_route(savedByMe: false)],
      ),
    );
    final states = <UserRoutesState>[];
    provider.addListener(() => states.add(provider.state));

    await provider.loadPublicRoutes(cityCode: 'almaty');

    expect(provider.publicRoutes.single.id, 'route_1');
    expect(provider.errorMessage, isNull);
    expect(states, [UserRoutesState.loading, UserRoutesState.success]);
  });

  test('saveRoute replaces route in public list and selected route', () async {
    final provider = UserRoutesProvider(
      userRoutesApi: _FakeUserRoutesApi(
        publicRoutes: [_route(savedByMe: false)],
        actionRoute: _route(savedByMe: true),
      ),
    );
    await provider.loadPublicRoutes();
    provider.setSelectedRoute(_route(savedByMe: false));

    final saved = await provider.saveRoute('route_1');

    expect(saved?.savedByMe, isTrue);
    expect(provider.publicRoutes.single.savedByMe, isTrue);
    expect(provider.selectedRoute?.savedByMe, isTrue);
  });

  test(
    'loadPublicRoutes converts Dio errors to provider error state',
    () async {
      final provider = UserRoutesProvider(
        userRoutesApi: _FakeUserRoutesApi(
          error: DioException(
            requestOptions: RequestOptions(path: '/user-routes'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/user-routes'),
              statusCode: 500,
              data: const {'message': 'Routes are unavailable.'},
            ),
          ),
        ),
      );

      await provider.loadPublicRoutes();

      expect(provider.state, UserRoutesState.error);
      expect(provider.errorMessage, 'Routes are unavailable.');
    },
  );

  test(
    'createFromBuiltRoute stores a private route draft in my routes',
    () async {
      late CreateUserRouteRequestVm capturedRequest;
      final provider = UserRoutesProvider(
        userRoutesApi: _FakeUserRoutesApi(
          onCreateRoute: (request) async {
            capturedRequest = request;
            return _route(savedByMe: false);
          },
        ),
      );

      final created = await provider.createFromBuiltRoute(
        title: 'Saved walk',
        route: const RouteResponseVm(
          provider: 'valhalla',
          mode: RouteMode.walking,
          profile: RouteProfile.touristWalk,
          distanceMeters: 1800,
          durationSeconds: 1320,
          geometry: RouteGeometryVm(encoding: '', points: []),
        ),
        points: const [
          RoutePointVm(
            latitude: 43.238949,
            longitude: 76.889709,
            name: 'Start',
          ),
          RoutePointVm(
            latitude: 43.239931,
            longitude: 76.912345,
            name: 'Finish',
          ),
        ],
      );

      expect(created?.id, 'route_1');
      expect(provider.myRoutes.single.id, 'route_1');
      expect(capturedRequest.title, 'Saved walk');
      expect(capturedRequest.visibility, UserRouteVisibility.private);
      expect(capturedRequest.points, hasLength(2));
    },
  );

  test('updateRoute replaces route in all local collections', () async {
    late UpdateUserRouteRequestVm capturedRequest;
    final updatedRoute = _route(
      savedByMe: false,
      title: 'Public coffee walk',
      visibility: UserRouteVisibility.unlisted,
    );
    final provider = UserRoutesProvider(
      userRoutesApi: _FakeUserRoutesApi(
        publicRoutes: [_route(savedByMe: false)],
        myRoutes: [_route(savedByMe: false)],
        onUpdateRoute: (routeId, request) async {
          expect(routeId, 'route_1');
          capturedRequest = request;
          return updatedRoute;
        },
      ),
    );
    await provider.loadPublicRoutes();
    await provider.loadMyRoutes();
    provider.setSelectedRoute(_route(savedByMe: false));

    final updated = await provider.updateRoute(
      'route_1',
      const UpdateUserRouteRequestVm(
        title: 'Public coffee walk',
        visibility: UserRouteVisibility.unlisted,
      ),
    );

    expect(updated?.title, 'Public coffee walk');
    expect(
      provider.publicRoutes.single.visibility,
      UserRouteVisibility.unlisted,
    );
    expect(provider.myRoutes.single.title, 'Public coffee walk');
    expect(provider.selectedRoute?.title, 'Public coffee walk');
    expect(capturedRequest.visibility, UserRouteVisibility.unlisted);
  });
}

class _FakeUserRoutesApi extends UserRoutesApi {
  _FakeUserRoutesApi({
    this.publicRoutes = const [],
    this.myRoutes = const [],
    this.actionRoute,
    this.onCreateRoute,
    this.onUpdateRoute,
    this.error,
  });

  final List<UserRouteVm> publicRoutes;
  final List<UserRouteVm> myRoutes;
  final UserRouteVm? actionRoute;
  final Future<UserRouteVm> Function(CreateUserRouteRequestVm request)?
  onCreateRoute;
  final Future<UserRouteVm> Function(
    String routeId,
    UpdateUserRouteRequestVm request,
  )?
  onUpdateRoute;
  final Object? error;

  @override
  Future<List<UserRouteVm>> listPublicRoutes({
    String? cityCode,
    int limit = 20,
    int offset = 0,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return publicRoutes;
  }

  @override
  Future<List<UserRouteVm>> listMyRoutes({
    int limit = 20,
    int offset = 0,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return myRoutes;
  }

  @override
  Future<UserRouteVm> saveRoute(String routeId) async {
    return actionRoute ?? _route(savedByMe: true);
  }

  @override
  Future<UserRouteVm> createRoute(CreateUserRouteRequestVm request) async {
    final handler = onCreateRoute;
    if (handler != null) {
      return handler(request);
    }
    return actionRoute ?? _route(savedByMe: false);
  }

  @override
  Future<UserRouteVm> updateRoute(
    String routeId,
    UpdateUserRouteRequestVm request,
  ) async {
    final handler = onUpdateRoute;
    if (handler != null) {
      return handler(routeId, request);
    }
    return actionRoute ?? _route(savedByMe: false);
  }
}

UserRouteVm _route({
  required bool savedByMe,
  String title = 'Алматы: кофе и парк',
  UserRouteVisibility visibility = UserRouteVisibility.public,
}) {
  return UserRouteVm(
    id: 'route_1',
    ownerUserId: 'user-1',
    title: title,
    visibility: visibility,
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
    stats: UserRouteStatsVm(
      savesCount: savedByMe ? 1 : 0,
      copiesCount: 0,
      viewsCount: 0,
    ),
    savedByMe: savedByMe,
  );
}
