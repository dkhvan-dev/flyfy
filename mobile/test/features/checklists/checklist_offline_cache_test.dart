import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/checklist_api.dart';
import 'package:inflap/features/checklists/data/checklist_offline_cache.dart';
import 'package:inflap/features/checklists/models/trip_checklist_vm.dart';
import 'package:inflap/features/checklists/models/travel_checklist_route_args.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores and restores trip checklist by trip id', () async {
    SharedPreferences.setMockInitialValues({});

    final cache = ChecklistOfflineCache();
    final checklist = _checklist('trip-1');

    await cache.saveTripChecklist('trip-1', checklist);
    final restored = await cache.readTripChecklist('trip-1');

    expect(restored?.tripId, 'trip-1');
    expect(restored?.readiness.score, 72);
    expect(restored?.items.single.id, 'documents.passport_id');
    expect(restored?.trustNotice.title, 'Cached guidance');
  });

  test('returns null for blank trip id and corrupted payload', () async {
    SharedPreferences.setMockInitialValues({
      'inflap.checklists.trip.dHJpcC0x': '{broken json',
    });

    final cache = ChecklistOfflineCache();

    expect(await cache.readTripChecklist(''), isNull);
    expect(await cache.readTripChecklist('trip-1'), isNull);
  });

  test('stores recent checklist entries with route context', () async {
    SharedPreferences.setMockInitialValues({});

    final cache = ChecklistOfflineCache();
    final routeArgs = TravelChecklistRouteArgs(
      tripId: 'quick-prep:tr:istanbul:2026-07-10',
      destination: const TripChecklistDestinationRequest(
        countryCode: 'TR',
        cityName: 'Стамбул',
        cityId: 'istanbul',
      ),
      startAt: DateTime.utc(2026, 7, 10, 9),
      endAt: DateTime.utc(2026, 7, 17, 18),
      transportModes: const ['flight'],
      activitySlugs: const ['culture'],
    );

    await cache.saveTripChecklist(
      routeArgs.normalizedTripId,
      _checklist(routeArgs.normalizedTripId),
      routeArgs: routeArgs,
    );

    final entries = await cache.listTripChecklistEntries();

    expect(entries, hasLength(1));
    expect(
      entries.single.routeArgs.normalizedTripId,
      routeArgs.normalizedTripId,
    );
    expect(entries.single.routeArgs.destination.cityName, 'Стамбул');
    expect(entries.single.readinessScore, 72);
  });

  test(
    'removes cached trip checklist and its recent entry by trip id',
    () async {
      SharedPreferences.setMockInitialValues({});

      final cache = ChecklistOfflineCache();
      final activityRouteArgs = _routeArgs(
        tripId: 'activity:activity-1',
        cityName: 'Almaty',
      );
      final quickPrepRouteArgs = _routeArgs(
        tripId: 'quick-prep:kz:almaty:2026-07-10',
        cityName: 'Almaty',
      );

      await cache.saveTripChecklist(
        activityRouteArgs.normalizedTripId,
        _checklist(activityRouteArgs.normalizedTripId),
        routeArgs: activityRouteArgs,
      );
      await cache.saveTripChecklist(
        quickPrepRouteArgs.normalizedTripId,
        _checklist(quickPrepRouteArgs.normalizedTripId),
        routeArgs: quickPrepRouteArgs,
      );

      await cache.removeTripChecklist(activityRouteArgs.normalizedTripId);

      final removedChecklist = await cache.readTripChecklist(
        activityRouteArgs.normalizedTripId,
      );
      final keptChecklist = await cache.readTripChecklist(
        quickPrepRouteArgs.normalizedTripId,
      );
      final entries = await cache.listTripChecklistEntries();

      expect(removedChecklist, isNull);
      expect(keptChecklist?.tripId, quickPrepRouteArgs.normalizedTripId);
      expect(entries, hasLength(1));
      expect(
        entries.single.routeArgs.normalizedTripId,
        quickPrepRouteArgs.normalizedTripId,
      );
    },
  );

  test(
    'stores and restores custom checklist items with personal progress',
    () async {
      SharedPreferences.setMockInitialValues({});

      final cache = ChecklistOfflineCache();
      final checklist = _checklistWithCustomItems('trip-custom');

      await cache.saveTripChecklist('trip-custom', checklist);
      final restored = await cache.readTripChecklist('trip-custom');

      expect(restored?.customItems, hasLength(1));
      expect(restored?.customItems.single.title, 'Camera charger');
      expect(restored?.customItems.single.reuseInFuture, isTrue);
      expect(restored?.personalProgress.total, 1);
      expect(restored?.personalProgress.done, 0);
    },
  );
}

TravelChecklistRouteArgs _routeArgs({
  required String tripId,
  required String cityName,
}) {
  return TravelChecklistRouteArgs(
    tripId: tripId,
    destination: TripChecklistDestinationRequest(
      countryCode: 'KZ',
      cityName: cityName,
    ),
    startAt: DateTime.utc(2026, 7, 10, 9),
    endAt: DateTime.utc(2026, 7, 17, 18),
    transportModes: const ['flight'],
    activitySlugs: const ['culture'],
  );
}

TripChecklistVm _checklist(String tripId) {
  return TripChecklistVm.fromJson({
    'instanceId': 'instance-1',
    'userId': 'user-1',
    'tripId': tripId,
    'readiness': {'score': 72, 'status': 'on_track', 'blockers': const []},
    'trustNotice': const {
      'code': 'verified_curated',
      'title': 'Cached guidance',
      'message': 'Offline copy',
    },
    'items': const [
      {
        'id': 'documents.passport_id',
        'category': 'documents',
        'priority': 'critical',
        'status': 'open',
        'title': 'Passport / ID',
        'reason': 'Check your document.',
        'trustLevel': 'official_link_required',
        'requiresUserConfirmation': true,
        'source': {'confidence': 'high'},
      },
    ],
    'generatedAt': '2026-06-20T00:00:00Z',
  });
}

TripChecklistVm _checklistWithCustomItems(String tripId) {
  return TripChecklistVm.fromJson({
    'instanceId': 'instance-1',
    'userId': 'user-1',
    'tripId': tripId,
    'readiness': {'score': 72, 'status': 'on_track', 'blockers': const []},
    'trustNotice': const {'code': 'verified_curated'},
    'items': const [],
    'customItems': const [
      {
        'id': 'custom-1',
        'title': 'Camera charger',
        'note': 'USB-C',
        'category': 'custom',
        'priority': 'recommended',
        'status': 'open',
        'reuseInFuture': true,
      },
    ],
    'personalProgress': const {'total': 1, 'done': 0, 'percent': 0},
    'generatedAt': '2026-06-20T00:00:00Z',
  });
}
