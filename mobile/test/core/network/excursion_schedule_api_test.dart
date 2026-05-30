import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/excursion_schedule_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/excursions/models/excursion_schedule_vm.dart';

void main() {
  test('getGuideSchedule sends UTC week range and parses items', () async {
    final adapter = _ScheduleJsonAdapter({
      '/me/excursion-schedule': {
        'items': [_slotJson()],
      },
    });
    final api = ExcursionScheduleApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final slots = await api.getGuideSchedule(
      from: DateTime.utc(2026, 6, 1),
      to: DateTime.utc(2026, 6, 8),
    );

    expect(adapter.requests.single.path, '/me/excursion-schedule');
    expect(adapter.requests.single.queryParameters, {
      'from': '2026-06-01T00:00:00.000Z',
      'to': '2026-06-08T00:00:00.000Z',
    });
    expect(slots.single.id, 'slot-1');
    expect(slots.single.status, ExcursionScheduleSlotStatus.available);
  });

  test('getPublicSchedule sends product offer range and seats', () async {
    final adapter = _ScheduleJsonAdapter({
      '/excursion-products/product%201/schedule': {
        'items': [_slotJson()],
      },
    });
    final api = ExcursionScheduleApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final slots = await api.getPublicSchedule(
      productId: 'product 1',
      offerId: 'offer-1',
      from: DateTime.utc(2026, 6, 1),
      to: DateTime.utc(2026, 6, 8),
      seats: 3,
    );

    expect(
      adapter.requests.single.path,
      '/excursion-products/product%201/schedule',
    );
    expect(adapter.requests.single.queryParameters, {
      'offerId': 'offer-1',
      'from': '2026-06-01T00:00:00.000Z',
      'to': '2026-06-08T00:00:00.000Z',
      'seats': 3,
    });
    expect(slots.single.id, 'slot-1');
  });

  test('createSlot posts request body and parses created slot', () async {
    final adapter = _ScheduleJsonAdapter({
      '/me/excursion-schedule/slots': _slotJson(id: 'slot-created'),
    });
    final api = ExcursionScheduleApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final slot = await api.createSlot(
      CreateExcursionScheduleSlotRequest(
        offerId: 'offer-1',
        startAt: DateTime.utc(2026, 6, 1, 8),
        timezone: 'Asia/Almaty',
        capacity: 6,
      ),
    );

    expect(adapter.requests.single.path, '/me/excursion-schedule/slots');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.lastJsonBody?['offerId'], 'offer-1');
    expect(adapter.lastJsonBody?['startAt'], '2026-06-01T08:00:00.000Z');
    expect(slot.id, 'slot-created');
  });

  test('updateSlot patches encoded id and parses updated slot', () async {
    final adapter = _ScheduleJsonAdapter({
      '/me/excursion-schedule/slots/slot%201': _slotJson(id: 'slot 1'),
    });
    final api = ExcursionScheduleApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final slot = await api.updateSlot(
      'slot 1',
      UpdateExcursionScheduleSlotRequest(
        offerId: 'offer-2',
        startAt: DateTime.utc(2026, 6, 5, 9, 30),
        timezone: 'Asia/Almaty',
        capacity: 5,
      ),
    );

    expect(
      adapter.requests.single.path,
      '/me/excursion-schedule/slots/slot%201',
    );
    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.lastJsonBody?['offerId'], 'offer-2');
    expect(adapter.lastJsonBody?['startAt'], '2026-06-05T09:30:00.000Z');
    expect(slot.id, 'slot 1');
  });

  test('deleteSlot encodes id and sends delete request', () async {
    final adapter = _ScheduleJsonAdapter({
      '/me/excursion-schedule/slots/slot%201': <String, dynamic>{},
    });
    final api = ExcursionScheduleApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    await api.deleteSlot('slot 1');

    expect(
      adapter.requests.single.path,
      '/me/excursion-schedule/slots/slot%201',
    );
    expect(adapter.requests.single.method, 'DELETE');
  });

  test('cancelSlot encodes id and posts cancel reason', () async {
    final adapter = _ScheduleJsonAdapter({
      '/me/excursion-schedule/slots/slot%201/cancel': _slotJson(
        id: 'slot 1',
        status: 'CANCELLED',
      ),
    });
    final api = ExcursionScheduleApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final slot = await api.cancelSlot('slot 1', 'guide is sick');

    expect(
      adapter.requests.single.path,
      '/me/excursion-schedule/slots/slot%201/cancel',
    );
    expect(adapter.lastJsonBody, {'reason': 'guide is sick'});
    expect(slot.status, ExcursionScheduleSlotStatus.cancelled);
  });
}

Map<String, dynamic> _slotJson({
  String id = 'slot-1',
  String status = 'AVAILABLE',
}) {
  return {
    'id': id,
    'seriesId': 'series-1',
    'offerId': 'offer-1',
    'productId': 'product-1',
    'legacyExcursionId': 'excursion-1',
    'startAt': '2026-06-01T08:00:00Z',
    'endAt': '2026-06-01T10:00:00Z',
    'timezone': 'Asia/Almaty',
    'capacity': 6,
    'bookedSeats': 0,
    'status': status,
    'title': 'Medeu sunrise walk',
  };
}

class _ScheduleJsonAdapter implements HttpClientAdapter {
  _ScheduleJsonAdapter(this.payloads);

  final Map<String, Object?> payloads;
  final List<RequestOptions> requests = [];
  Map<String, dynamic>? lastJsonBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.data is Map<String, dynamic>) {
      lastJsonBody = options.data as Map<String, dynamic>;
    }
    final payload = payloads[options.path];
    if (payload == null) {
      return ResponseBody.fromString(
        jsonEncode({'error': 'not found'}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
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

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';
}
