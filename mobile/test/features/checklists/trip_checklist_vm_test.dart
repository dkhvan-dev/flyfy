import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/checklists/models/trip_checklist_vm.dart';

void main() {
  test(
    'parses readiness, localized checklist items, and source confidence',
    () {
      final vm = TripChecklistVm.fromJson(const {
        'instanceId': 'instance-1',
        'userId': 'user-42',
        'tripId': 'tokyo-july',
        'readiness': {
          'score': 50,
          'status': 'not_ready',
          'blockers': [
            {
              'itemId': 'documents.entry_requirements_self_check',
              'priority': 'critical',
              'reason': 'Проверьте требования въезда',
            },
          ],
        },
        'trustNotice': {
          'code': 'official_source_required',
          'title': 'Нужна проверка',
          'message': 'Проверьте официальные источники',
        },
        'items': [
          {
            'id': 'weather.tokyo_july_rain_heat',
            'category': 'weather',
            'priority': 'important',
            'status': 'open',
            'title': 'Защита от жары и дождя',
            'reason': 'В июле в Токио обычно жарко, влажно и часто дождливо.',
            'trustLevel': 'verified_curated',
            'requiresUserConfirmation': false,
            'source': {
              'name': 'World Bank Climate Change Knowledge Portal',
              'url':
                  'https://climateknowledgeportal.worldbank.org/download-data',
              'type': 'open_data',
              'confidence': 'medium',
            },
          },
        ],
        'seasonalProfile': {
          'month': 7,
          'temperatureBand': 'hot',
          'precipitationBand': 'rainy',
          'skyBand': 'mixed',
          'riskTags': ['humid', 'rain'],
          'packingImplications': ['Легкая одежда', 'Защита от дождя'],
          'source': {
            'name': 'World Bank Climate Change Knowledge Portal',
            'url': 'https://climateknowledgeportal.worldbank.org/download-data',
            'type': 'open_data',
            'confidence': 'medium',
          },
        },
        'generatedAt': '2026-06-20T00:00:00Z',
        'updatedAt': '2026-06-20T00:05:00Z',
      });

      expect(vm.instanceId, 'instance-1');
      expect(vm.userId, 'user-42');
      expect(vm.tripId, 'tokyo-july');
      expect(vm.readiness.score, 50);
      expect(vm.readiness.status, ChecklistReadinessStatus.notReady);
      expect(
        vm.readiness.blockers.single.itemId,
        'documents.entry_requirements_self_check',
      );
      expect(
        vm.items.single.source.confidence,
        ChecklistSourceConfidence.medium,
      );
      expect(vm.seasonalProfile?.precipitationBand, 'rainy');
      expect(vm.trustNotice.code, 'official_source_required');
      expect(vm.updatedAt, DateTime.utc(2026, 6, 20, 0, 5));
    },
  );

  test('parses carry item policy response', () {
    final items = CarryItemPolicyListVm.fromJson(const {
      'items': [
        {
          'itemSlug': 'power_bank',
          'carryOn': 'allowed_with_conditions',
          'checkedBaggage': 'prohibited',
          'requiresAirlineCheck': true,
          'conditionSummary': 'Только ручная кладь',
          'source': {
            'name': 'FAA PackSafe',
            'url': 'https://www.faa.gov/hazmat/packsafe/lithium-batteries',
            'type': 'official_authority',
            'confidence': 'high',
          },
        },
      ],
    });

    expect(items.items.single.itemSlug, 'power_bank');
    expect(items.items.single.checkedBaggage, CarryPolicy.prohibited);
    expect(items.items.single.carryOn, CarryPolicy.allowedWithConditions);
    expect(items.items.single.requiresAirlineCheck, isTrue);
  });

  test('parses custom checklist items and separate personal progress', () {
    final vm = TripChecklistVm.fromJson(const {
      'instanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': 'tokyo-july',
      'items': [],
      'readiness': {'score': 80, 'status': 'on_track', 'blockers': []},
      'trustNotice': {'code': 'verified_curated'},
      'customItems': [
        {
          'id': 'custom-1',
          'title': 'Зарядка для камеры',
          'note': 'USB-C',
          'category': 'custom',
          'priority': 'recommended',
          'status': 'open',
          'assignedUserId': 'user-42',
          'reuseInFuture': true,
          'personalTemplateId': 'template-1',
          'createdAt': '2026-06-21T10:00:00Z',
          'updatedAt': '2026-06-21T10:05:00Z',
        },
      ],
      'personalProgress': {'total': 1, 'done': 0, 'percent': 0},
      'generatedAt': '2026-06-20T00:00:00Z',
    });

    expect(vm.readiness.score, 80);
    expect(vm.personalProgress.total, 1);
    expect(vm.personalProgress.done, 0);
    expect(vm.personalProgress.percent, 0);
    expect(vm.customItems.single.id, 'custom-1');
    expect(vm.customItems.single.title, 'Зарядка для камеры');
    expect(vm.customItems.single.note, 'USB-C');
    expect(vm.customItems.single.assignedUserId, 'user-42');
    expect(vm.customItems.single.reuseInFuture, isTrue);
    expect(vm.customItems.single.personalTemplateId, 'template-1');
    expect(vm.customItems.single.isDone, isFalse);
    expect(vm.customItems.single.updatedAt, DateTime.utc(2026, 6, 21, 10, 5));

    final encoded = vm.toJson();
    expect(encoded['customItems'], isA<List<Object?>>());
    expect(encoded['personalProgress'], {'total': 1, 'done': 0, 'percent': 0});
  });
}
