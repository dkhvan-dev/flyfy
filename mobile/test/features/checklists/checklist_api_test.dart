import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/checklist_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/checklists/models/trip_checklist_vm.dart';

void main() {
  test(
    'previewTripChecklist posts trip context to authenticated endpoint',
    () async {
      final adapter = _ChecklistAdapter({
        'tripId': 'tokyo-july',
        'items': const [],
        'readiness': {'score': 50, 'status': 'not_ready', 'blockers': const []},
        'trustNotice': {'code': 'official_source_required'},
        'generatedAt': '2026-06-20T00:00:00Z',
      });
      final api = ChecklistApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final checklist = await api.previewTripChecklist(
        TripChecklistPreviewRequest(
          tripId: 'tokyo-july',
          destination: const TripChecklistDestinationRequest(
            countryCode: 'JP',
            cityName: 'Tokyo',
          ),
          startAt: DateTime.utc(2026, 7, 11, 10),
          endAt: DateTime.utc(2026, 7, 18, 10),
          transportModes: const ['flight'],
          activitySlugs: const ['hiking'],
          preferredLanguage: 'ru',
        ),
      );

      expect(adapter.requestPath, '/api/v1/checklists/trip-preview');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.body?['tripId'], 'tokyo-july');
      expect(adapter.body?['destination'], {
        'countryCode': 'JP',
        'cityName': 'Tokyo',
      });
      expect(adapter.body?['transportModes'], ['flight']);
      expect(adapter.body?['travelerProfile'], {'preferredLanguage': 'ru'});
      expect(checklist.readiness.score, 50);
    },
  );

  test(
    'getOrCreateTripChecklist posts trip context to persisted endpoint',
    () async {
      final adapter = _ChecklistAdapter({
        'instanceId': 'instance-1',
        'userId': 'user-42',
        'tripId': 'tokyo-july',
        'items': const [],
        'readiness': {'score': 50, 'status': 'not_ready', 'blockers': const []},
        'trustNotice': {'code': 'official_source_required'},
        'generatedAt': '2026-06-20T00:00:00Z',
        'updatedAt': '2026-06-20T00:05:00Z',
      });
      final api = ChecklistApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final checklist = await api.getOrCreateTripChecklist(
        TripChecklistPreviewRequest(
          tripId: 'tokyo-july',
          destination: const TripChecklistDestinationRequest(
            countryCode: 'JP',
            cityName: 'Tokyo',
          ),
          startAt: DateTime.utc(2026, 7, 11, 10),
          endAt: DateTime.utc(2026, 7, 18, 10),
          transportModes: const ['flight'],
          activitySlugs: const ['hiking'],
          preferredLanguage: 'en',
        ),
      );

      expect(adapter.method, 'POST');
      expect(adapter.requestPath, '/api/v1/checklists/trips');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.body?['tripId'], 'tokyo-july');
      expect(checklist.instanceId, 'instance-1');
      expect(checklist.userId, 'user-42');
    },
  );

  test(
    'listTripChecklists gets authenticated server-backed summaries',
    () async {
      final adapter = _ChecklistAdapter({
        'items': [
          {
            'instanceId': 'instance-1',
            'userId': 'user-42',
            'tripId': 'quick-prep:tr:istanbul:2026-07-10',
            'destination': {
              'countryCode': 'TR',
              'countryName': 'Турция',
              'cityName': 'Istanbul',
              'cityId': 'istanbul',
            },
            'startAt': '2026-07-10T09:00:00Z',
            'endAt': '2026-07-17T18:00:00Z',
            'transportModes': ['flight'],
            'activitySlugs': ['culture'],
            'hasChildren': true,
            'readiness': {'score': 72, 'status': 'on_track'},
            'itemCount': 6,
            'updatedAt': '2026-06-20T12:00:00Z',
          },
        ],
      });
      final api = ChecklistApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final summaries = await api.listTripChecklists(locale: 'ru', limit: 30);

      expect(adapter.method, 'GET');
      expect(adapter.requestPath, '/api/v1/checklists/trips');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.queryParameters, {'lang': 'ru', 'limit': '30'});
      expect(summaries, hasLength(1));
      expect(summaries.single.tripId, 'quick-prep:tr:istanbul:2026-07-10');
      expect(summaries.single.destination.countryCode, 'TR');
      expect(summaries.single.destinationCountryName, 'Турция');
      expect(summaries.single.activitySlugs, ['culture']);
      expect(summaries.single.hasChildren, isTrue);
      expect(summaries.single.readinessScore, 72);
      expect(summaries.single.readinessStatus, 'on_track');
      expect(summaries.single.itemCount, 6);
    },
  );

  test('updateChecklistItemStatus patches persisted item status', () async {
    final adapter = _ChecklistAdapter({
      'instanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': 'tokyo-july',
      'items': [
        {'id': 'documents.passport_id', 'status': 'done'},
      ],
      'readiness': {'score': 75, 'status': 'on_track', 'blockers': const []},
      'trustNotice': {'code': 'official_source_required'},
      'generatedAt': '2026-06-20T00:00:00Z',
      'updatedAt': '2026-06-20T00:05:00Z',
    });
    final api = ChecklistApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final checklist = await api.updateChecklistItemStatus(
      tripId: 'tokyo-july',
      itemId: 'documents.passport_id',
      status: 'done',
      locale: 'en',
    );

    expect(adapter.method, 'PATCH');
    expect(
      adapter.requestPath,
      '/api/v1/checklists/trips/tokyo-july/items/documents.passport_id',
    );
    expect(adapter.queryParameters, {'lang': 'en'});
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.body, {'status': 'done'});
    expect(checklist.items.single.status, 'done');
  });

  test('submitChecklistItemFeedback posts learning signal', () async {
    final adapter = _ChecklistAdapter({
      'id': 'feedback-1',
      'checklistInstanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': 'tokyo-july',
      'itemId': 'documents.passport_id',
      'type': 'helpful',
      'comment': 'Useful reminder',
      'createdAt': '2026-06-20T00:06:00Z',
    });
    final api = ChecklistApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final feedback = await api.submitChecklistItemFeedback(
      tripId: 'tokyo-july',
      itemId: 'documents.passport_id',
      type: ChecklistItemFeedbackType.helpful,
      comment: 'Useful reminder',
      locale: 'en',
    );

    expect(adapter.method, 'POST');
    expect(
      adapter.requestPath,
      '/api/v1/checklists/trips/tokyo-july/items/documents.passport_id/feedback',
    );
    expect(adapter.queryParameters, {'lang': 'en'});
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.body, {'type': 'helpful', 'comment': 'Useful reminder'});
    expect(feedback.id, 'feedback-1');
    expect(feedback.type, ChecklistItemFeedbackType.helpful);
  });

  test(
    'listTripChecklistReminders fetches authenticated reminder schedule',
    () async {
      final adapter = _ChecklistAdapter({
        'items': [
          {
            'id': 'trip-30-days-before',
            'offsetDays': 30,
            'dueAt': '2026-06-11T10:00:00Z',
            'status': 'scheduled',
            'title': 'Document check',
            'message': 'Confirm documents',
          },
        ],
      });
      final api = ChecklistApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final reminders = await api.listTripChecklistReminders(
        tripId: 'tokyo-july',
        locale: 'en',
      );

      expect(adapter.method, 'GET');
      expect(
        adapter.requestPath,
        '/api/v1/checklists/trips/tokyo-july/reminders',
      );
      expect(adapter.queryParameters, {'lang': 'en'});
      expect(adapter.requiresAuth, isTrue);
      expect(reminders.items.single.offsetDays, 30);
    },
  );

  test('setChecklistItemAssignment updates shared checklist assignee', () async {
    final adapter = _ChecklistAdapter({
      'instanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': 'tokyo-july',
      'items': [
        {
          'id': 'documents.passport_id',
          'status': 'open',
          'assignedUserId': 'user-42',
        },
      ],
      'readiness': {'score': 50, 'status': 'not_ready', 'blockers': const []},
      'trustNotice': {'code': 'official_source_required'},
      'generatedAt': '2026-06-20T00:00:00Z',
      'updatedAt': '2026-06-20T00:05:00Z',
    });
    final api = ChecklistApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final checklist = await api.setChecklistItemAssignment(
      tripId: 'tokyo-july',
      itemId: 'documents.passport_id',
      assignToMe: true,
      locale: 'en',
    );

    expect(adapter.method, 'PATCH');
    expect(
      adapter.requestPath,
      '/api/v1/checklists/trips/tokyo-july/items/documents.passport_id/assignment',
    );
    expect(adapter.queryParameters, {'lang': 'en'});
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.body, {'assignToMe': true});
    expect(checklist.items.single.assignedUserId, 'user-42');
  });

  test('searchCarryItems sends public query through gateway', () async {
    final adapter = _ChecklistAdapter({
      'items': [
        {
          'itemSlug': 'power_bank',
          'carryOn': 'allowed_with_conditions',
          'checkedBaggage': 'prohibited',
          'requiresAirlineCheck': true,
          'conditionSummary': 'Carry-on only',
          'source': {'confidence': 'high'},
        },
      ],
    });
    final api = ChecklistApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final result = await api.searchCarryItems(
      query: 'power bank',
      transportMode: 'flight',
      locale: 'en',
    );

    expect(adapter.requestPath, '/api/v1/checklists/carry-items/search');
    expect(adapter.requiresAuth, isFalse);
    expect(adapter.queryParameters, {
      'q': 'power bank',
      'transportMode': 'flight',
      'lang': 'en',
    });
    expect(result.items.single.itemSlug, 'power_bank');
  });

  test(
    'createCustomChecklistItem posts authenticated custom item payload',
    () async {
      final adapter = _ChecklistAdapter({
        'instanceId': 'instance-1',
        'userId': 'user-42',
        'tripId': 'tokyo-july',
        'items': const [],
        'customItems': [
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
        'personalProgress': {'total': 1, 'done': 0, 'percent': 0},
        'readiness': {'score': 50, 'status': 'not_ready', 'blockers': const []},
        'trustNotice': {'code': 'verified_curated'},
        'generatedAt': '2026-06-20T00:00:00Z',
      });
      final api = ChecklistApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final checklist = await api.createCustomChecklistItem(
        tripId: 'tokyo-july',
        request: const CustomChecklistItemRequest(
          title: 'Camera charger',
          note: 'USB-C',
          category: 'custom',
          priority: 'recommended',
          reuseInFuture: true,
        ),
        locale: 'en',
      );

      expect(adapter.method, 'POST');
      expect(
        adapter.requestPath,
        '/api/v1/checklists/trips/tokyo-july/custom-items',
      );
      expect(adapter.queryParameters, {'lang': 'en'});
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.body, {
        'title': 'Camera charger',
        'note': 'USB-C',
        'category': 'custom',
        'priority': 'recommended',
        'reuseInFuture': true,
      });
      expect(checklist.customItems.single.title, 'Camera charger');
      expect(checklist.personalProgress.total, 1);
    },
  );

  test('updateCustomChecklistItemStatus patches custom item status', () async {
    final adapter = _ChecklistAdapter({
      'instanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': 'tokyo-july',
      'items': const [],
      'customItems': [
        {'id': 'custom-1', 'title': 'Camera charger', 'status': 'done'},
      ],
      'personalProgress': {'total': 1, 'done': 1, 'percent': 100},
      'readiness': {'score': 50, 'status': 'not_ready', 'blockers': const []},
      'trustNotice': {'code': 'verified_curated'},
      'generatedAt': '2026-06-20T00:00:00Z',
    });
    final api = ChecklistApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final checklist = await api.updateCustomChecklistItemStatus(
      tripId: 'tokyo-july',
      itemId: 'custom-1',
      status: 'done',
      locale: 'en',
    );

    expect(adapter.method, 'PATCH');
    expect(
      adapter.requestPath,
      '/api/v1/checklists/trips/tokyo-july/custom-items/custom-1/status',
    );
    expect(adapter.queryParameters, {'lang': 'en'});
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.body, {'status': 'done'});
    expect(checklist.customItems.single.isDone, isTrue);
    expect(checklist.personalProgress.done, 1);
  });

  test('deleteCustomChecklistItem deletes authenticated custom item', () async {
    final adapter = _ChecklistAdapter({
      'instanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': 'tokyo-july',
      'items': const [],
      'customItems': const [],
      'personalProgress': {'total': 0, 'done': 0, 'percent': 0},
      'readiness': {'score': 50, 'status': 'not_ready', 'blockers': const []},
      'trustNotice': {'code': 'verified_curated'},
      'generatedAt': '2026-06-20T00:00:00Z',
    });
    final api = ChecklistApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final checklist = await api.deleteCustomChecklistItem(
      tripId: 'tokyo-july',
      itemId: 'custom-1',
      locale: 'en',
    );

    expect(adapter.method, 'DELETE');
    expect(
      adapter.requestPath,
      '/api/v1/checklists/trips/tokyo-july/custom-items/custom-1',
    );
    expect(adapter.queryParameters, {'lang': 'en'});
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.body, isNull);
    expect(checklist.customItems, isEmpty);
    expect(checklist.personalProgress.total, 0);
  });
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _ChecklistAdapter implements HttpClientAdapter {
  _ChecklistAdapter(this.payload);

  final Map<String, Object?> payload;
  String? method;
  String? requestPath;
  bool? requiresAuth;
  Map<String, dynamic>? body;
  Map<String, String>? queryParameters;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    requestPath = options.uri.path;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    queryParameters = Map<String, String>.from(options.uri.queryParameters);
    final requestBytes = await requestStream?.expand((chunk) => chunk).toList();
    if (requestBytes != null && requestBytes.isNotEmpty) {
      body = jsonDecode(utf8.decode(requestBytes)) as Map<String, dynamic>;
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
