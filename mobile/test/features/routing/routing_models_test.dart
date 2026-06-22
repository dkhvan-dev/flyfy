import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/routing/models/routing_models.dart';

void main() {
  test('RouteResponse parses provider profile mode and encoded geometry', () {
    final response = RouteResponseVm.fromJson(const {
      'provider': 'valhalla',
      'mode': 'walking',
      'profile': 'tourist_walk',
      'distanceMeters': 1234.5,
      'durationSeconds': 900,
      'geometry': {'encoding': 'polyline6', 'polyline': 'encoded'},
      'warnings': [
        {'code': 'stairs_possible', 'message': 'Some stairs may be present'},
      ],
    });

    expect(response.provider, 'valhalla');
    expect(response.mode, RouteMode.walking);
    expect(response.profile, RouteProfile.touristWalk);
    expect(response.distanceMeters, 1234.5);
    expect(response.durationSeconds, 900);
    expect(response.geometry.encoding, 'polyline6');
    expect(response.geometry.polyline, 'encoded');
    expect(response.warnings.single.code, 'stairs_possible');
  });

  test('RouteGeometry decodes polyline6 into display points', () {
    final geometry = RouteGeometryVm.fromJson(const {
      'encoding': 'polyline6',
      'polyline': '??AA',
    });

    expect(geometry.displayPoints, hasLength(2));
    expect(geometry.displayPoints.first.latitude, 0);
    expect(geometry.displayPoints.first.longitude, 0);
    expect(geometry.displayPoints.last.latitude, closeTo(0.000001, 0.0000001));
    expect(geometry.displayPoints.last.longitude, closeTo(0.000001, 0.0000001));
  });

  test('RouteRequest serializes compact backend contract', () {
    final request = RouteRequestVm(
      profile: RouteProfile.guideRoute,
      points: const [
        RoutePointVm(latitude: 43.238949, longitude: 76.889709, name: 'Hotel'),
        RoutePointVm(latitude: 43.255058, longitude: 76.912628),
      ],
    );

    expect(request.toJson(), {
      'profile': 'guide_route',
      'points': [
        {'latitude': 43.238949, 'longitude': 76.889709, 'name': 'Hotel'},
        {'latitude': 43.255058, 'longitude': 76.912628},
      ],
    });
  });

  test('advanced routing requests serialize backend contracts', () {
    const origin = RoutePointVm(latitude: 43.238949, longitude: 76.889709);
    const destination = RoutePointVm(latitude: 43.255058, longitude: 76.912628);

    expect(
      MatrixRequestVm(
        profile: RouteProfile.carStandard,
        origins: const [origin],
        destinations: const [destination],
      ).toJson(),
      {
        'profile': 'car_standard',
        'origins': [
          {'latitude': 43.238949, 'longitude': 76.889709},
        ],
        'destinations': [
          {'latitude': 43.255058, 'longitude': 76.912628},
        ],
      },
    );
    expect(
      IsochroneRequestVm(
        profile: RouteProfile.touristWalk,
        origin: origin,
        minutes: const [15, 30],
      ).toJson(),
      {
        'profile': 'tourist_walk',
        'origin': {'latitude': 43.238949, 'longitude': 76.889709},
        'minutes': [15, 30],
      },
    );
    expect(
      ItineraryOptimizationRequestVm(
        profile: RouteProfile.dayPlan,
        start: origin,
        stops: const [destination],
      ).toJson(),
      {
        'profile': 'day_plan',
        'start': {'latitude': 43.238949, 'longitude': 76.889709},
        'stops': [
          {'latitude': 43.255058, 'longitude': 76.912628},
        ],
      },
    );
    expect(
      MapMatchRequestVm(
        profile: RouteProfile.touristWalk,
        trace: const [origin, destination],
      ).toJson(),
      {
        'profile': 'tourist_walk',
        'trace': [
          {'latitude': 43.238949, 'longitude': 76.889709},
          {'latitude': 43.255058, 'longitude': 76.912628},
        ],
      },
    );
  });

  test('advanced routing responses parse nested route data', () {
    final matrix = MatrixResponseVm.fromJson(const {
      'provider': 'osrm',
      'rows': [
        {
          'cells': [
            {'distanceMeters': 1200, 'durationSeconds': 600, 'reachable': true},
          ],
        },
      ],
    });
    final itinerary = ItineraryOptimizationResponseVm.fromJson(const {
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
    final mapMatch = MapMatchResponseVm.fromJson(const {
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

    expect(matrix.rows.single.cells.single.reachable, isTrue);
    expect(itinerary.orderedStops.single.latitude, 43.255058);
    expect(itinerary.route.profile, RouteProfile.dayPlan);
    expect(mapMatch.route.durationSeconds, 42);
  });

  test('RouteResponse combines multi-leg geometry for map display', () {
    final response = RouteResponseVm.fromJson(const {
      'provider': 'valhalla',
      'mode': 'walking',
      'profile': 'day_plan',
      'distanceMeters': 12,
      'durationSeconds': 10,
      'geometry': {'encoding': 'polyline6', 'polyline': '??AA'},
      'legs': [
        {
          'fromIndex': 0,
          'toIndex': 1,
          'distanceMeters': 6,
          'durationSeconds': 5,
          'geometry': {'encoding': 'polyline6', 'polyline': '??AA'},
        },
        {
          'fromIndex': 1,
          'toIndex': 2,
          'distanceMeters': 6,
          'durationSeconds': 5,
          'geometry': {'encoding': 'polyline6', 'polyline': 'AAAC'},
        },
      ],
    });

    expect(response.legs, hasLength(2));
    expect(response.displayPoints, hasLength(3));
    expect(response.displayPoints.last.latitude, closeTo(0.000002, 0.0000001));
    expect(response.displayPoints.last.longitude, closeTo(0.000003, 0.0000001));
  });
}
