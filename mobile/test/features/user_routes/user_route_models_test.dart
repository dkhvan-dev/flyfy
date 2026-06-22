import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/routing/models/routing_models.dart';
import 'package:inflap/features/user_routes/models/user_route_models.dart';

void main() {
  test('UserRoute parses backend route content snapshot and viewer state', () {
    final route = UserRouteVm.fromJson(const {
      'id': 'route_1',
      'ownerUserId': 'user-1',
      'title': 'Алматы: кофе и парк',
      'description': 'Легкая прогулка',
      'visibility': 'public',
      'profile': 'tourist_walk',
      'cityCode': 'almaty',
      'tags': ['coffee', 'park'],
      'points': [
        {
          'id': 'point-1',
          'latitude': 43.238949,
          'longitude': 76.889709,
          'name': 'Кофейня',
        },
        {
          'id': 'point-2',
          'latitude': 43.239931,
          'longitude': 76.912345,
          'name': 'Парк',
        },
      ],
      'snapshot': {
        'provider': 'valhalla',
        'mode': 'walking',
        'profile': 'tourist_walk',
        'distanceMeters': 1800,
        'durationSeconds': 1320,
        'encodedPolyline': 'encoded-route',
      },
      'stats': {'savesCount': 3, 'copiesCount': 1, 'viewsCount': 9},
      'savedByMe': true,
      'createdAt': '2026-06-22T09:00:00Z',
      'updatedAt': '2026-06-22T09:05:00Z',
    });

    expect(route.id, 'route_1');
    expect(route.visibility, UserRouteVisibility.public);
    expect(route.profile, RouteProfile.touristWalk);
    expect(route.points, hasLength(2));
    expect(route.snapshot.mode, RouteMode.walking);
    expect(route.snapshot.distanceMeters, 1800);
    expect(route.stats.savesCount, 3);
    expect(route.savedByMe, isTrue);
  });

  test('CreateUserRouteRequest serializes backend route content contract', () {
    final request = CreateUserRouteRequestVm(
      title: 'City walk',
      description: 'Two-stop walk',
      visibility: UserRouteVisibility.public,
      profile: RouteProfile.touristWalk,
      cityCode: 'almaty',
      tags: const ['coffee', 'park'],
      points: const [
        UserRoutePointVm(
          latitude: 43.238949,
          longitude: 76.889709,
          name: 'Start',
        ),
        UserRoutePointVm(
          latitude: 43.239931,
          longitude: 76.912345,
          name: 'Finish',
        ),
      ],
      snapshot: const UserRouteSnapshotVm(
        provider: 'valhalla',
        mode: RouteMode.walking,
        profile: RouteProfile.touristWalk,
        distanceMeters: 1800,
        durationSeconds: 1320,
        encodedPolyline: 'encoded-route',
      ),
    );

    expect(request.toJson(), {
      'title': 'City walk',
      'description': 'Two-stop walk',
      'visibility': 'public',
      'profile': 'tourist_walk',
      'cityCode': 'almaty',
      'tags': ['coffee', 'park'],
      'points': [
        {'latitude': 43.238949, 'longitude': 76.889709, 'name': 'Start'},
        {'latitude': 43.239931, 'longitude': 76.912345, 'name': 'Finish'},
      ],
      'snapshot': {
        'provider': 'valhalla',
        'mode': 'walking',
        'profile': 'tourist_walk',
        'distanceMeters': 1800,
        'durationSeconds': 1320,
        'encodedPolyline': 'encoded-route',
      },
    });
  });

  test('CreateUserRouteRequest builds private draft from calculated route', () {
    final request = CreateUserRouteRequestVm.fromBuiltRoute(
      title: 'Saved walk',
      route: const RouteResponseVm(
        provider: 'valhalla',
        mode: RouteMode.walking,
        profile: RouteProfile.touristWalk,
        distanceMeters: 1420.6,
        durationSeconds: 960,
        geometry: RouteGeometryVm(
          encoding: 'polyline6',
          polyline: 'encoded-route',
          points: [
            RoutePointVm(latitude: 43.238949, longitude: 76.889709),
            RoutePointVm(latitude: 43.239931, longitude: 76.912345),
          ],
        ),
      ),
      points: const [
        RoutePointVm(latitude: 43.238949, longitude: 76.889709, name: 'Start'),
        RoutePointVm(latitude: 43.239931, longitude: 76.912345, name: 'Finish'),
      ],
    );

    expect(request.visibility, UserRouteVisibility.private);
    expect(request.profile, RouteProfile.touristWalk);
    expect(request.points.map((point) => point.name), ['Start', 'Finish']);
    expect(request.snapshot.distanceMeters, 1421);
    expect(request.snapshot.encodedPolyline, 'encoded-route');
    expect(request.snapshot.geometryGeoJson, contains('"LineString"'));
  });

  test('UpdateUserRouteRequest serializes only edited fields', () {
    final request = UpdateUserRouteRequestVm(
      title: 'Public coffee walk',
      description: 'Shared route',
      visibility: UserRouteVisibility.unlisted,
    );

    expect(request.toJson(), {
      'title': 'Public coffee walk',
      'description': 'Shared route',
      'visibility': 'unlisted',
    });
  });

  test('UserRoute snapshot rebuilds route response with display geometry', () {
    const snapshot = UserRouteSnapshotVm(
      provider: 'valhalla',
      mode: RouteMode.walking,
      profile: RouteProfile.touristWalk,
      distanceMeters: 1421,
      durationSeconds: 960,
      encodedPolyline: 'encoded-route',
      geometryGeoJson:
          '{"type":"LineString","coordinates":[[76.889709,43.238949],[76.912345,43.239931]]}',
    );

    final route = snapshot.toRouteResponse();

    expect(route.provider, 'valhalla');
    expect(route.profile, RouteProfile.touristWalk);
    expect(route.displayPoints, hasLength(2));
    expect(route.displayPoints.first.latitude, 43.238949);
    expect(route.displayPoints.last.longitude, 76.912345);
  });
}
