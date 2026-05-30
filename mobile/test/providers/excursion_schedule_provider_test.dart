import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/excursion_schedule_api.dart';
import 'package:inflap/features/excursions/models/excursion_schedule_vm.dart';
import 'package:inflap/providers/excursion_schedule_provider.dart';

void main() {
  test('loadWeek requests Monday-start week and exposes slots for selected day',
      () async {
    final api = _FakeExcursionScheduleApi(
      slots: [
        _slot('later', DateTime.utc(2026, 6, 3, 12)),
        _slot('earlier', DateTime.utc(2026, 6, 3, 8)),
        _slot('other-day', DateTime.utc(2026, 6, 4, 8)),
      ],
    );
    final provider = ExcursionScheduleProvider(scheduleApi: api);

    await provider.loadWeek(DateTime(2026, 6, 3, 15));

    expect(provider.state, ExcursionScheduleState.success);
    expect(provider.selectedDate, DateTime(2026, 6, 3, 15));
    expect(api.lastFrom, DateTime(2026, 6, 1).toUtc());
    expect(api.lastTo, DateTime(2026, 6, 8).toUtc());
    expect(
      provider.slotsForDay(DateTime(2026, 6, 3)).map((slot) => slot.id),
      ['earlier', 'later'],
    );
  });

  test('selectDate inside loaded week only updates local selection', () async {
    final api = _FakeExcursionScheduleApi(slots: [_slot('slot-1')]);
    final provider = ExcursionScheduleProvider(scheduleApi: api);

    await provider.loadWeek(DateTime(2026, 6, 3));
    provider.selectDate(DateTime(2026, 6, 5));

    expect(provider.selectedDate, DateTime(2026, 6, 5));
    expect(api.loadCalls, 1);
  });

  test('loadWeek can request a public guide schedule by user id', () async {
    final api = _FakeExcursionScheduleApi(slots: [_slot('public-slot')]);
    final provider = ExcursionScheduleProvider(scheduleApi: api);

    await provider.loadWeek(DateTime(2026, 6, 3), guideUserId: 'guide-1');

    expect(provider.state, ExcursionScheduleState.success);
    expect(api.loadCalls, 0);
    expect(api.publicLoadCalls, 1);
    expect(api.lastGuideUserId, 'guide-1');
    expect(provider.isDateInLoadedWeek(DateTime(2026, 6, 4)), isFalse);
    expect(
      provider.isDateInLoadedWeek(
        DateTime(2026, 6, 4),
        guideUserId: 'guide-1',
      ),
      isTrue,
    );
  });

  test('mutations update local slot list', () async {
    final created = _slot('created', DateTime.utc(2026, 6, 3, 8));
    final updated = _slot('created', DateTime.utc(2026, 6, 5, 9));
    final api = _FakeExcursionScheduleApi(
      slots: [_slot('slot-1')],
      createdSlot: created,
      updatedSlot: updated,
      closedSlot: _slot(
        'created',
        DateTime.utc(2026, 6, 5, 9),
        ExcursionScheduleSlotStatus.closed,
      ),
    );
    final provider = ExcursionScheduleProvider(scheduleApi: api);

    await provider.loadWeek(DateTime(2026, 6, 3));
    final createOk = await provider.createSlot(
      CreateExcursionScheduleSlotRequest(
        offerId: 'offer-1',
        startAt: DateTime.utc(2026, 6, 3, 8),
        timezone: 'Asia/Almaty',
      ),
    );
    final updateOk = await provider.updateSlot(
      'created',
      UpdateExcursionScheduleSlotRequest(
        offerId: 'offer-1',
        startAt: DateTime.utc(2026, 6, 5, 9),
        timezone: 'Asia/Almaty',
      ),
    );
    final closeOk = await provider.closeSlot('created');
    final deleteOk = await provider.deleteSlot('slot-1');

    expect(createOk, isTrue);
    expect(updateOk, isTrue);
    expect(closeOk, isTrue);
    expect(deleteOk, isTrue);
    expect(provider.actionState, ExcursionScheduleActionState.success);
    expect(provider.slots.map((slot) => slot.id), ['created']);
    expect(provider.slots.single.status, ExcursionScheduleSlotStatus.closed);
    expect(provider.selectedDate, DateTime.utc(2026, 6, 5, 9).toLocal());
  });

  test('createSlot selects the saved slot date instead of the old calendar day',
      () async {
    final createdAt = DateTime.utc(2026, 6, 12, 9);
    final api = _FakeExcursionScheduleApi(
      slots: [_slot('current', DateTime.utc(2026, 6, 3, 8))],
      createdSlot: _slot('future', createdAt),
    );
    final provider = ExcursionScheduleProvider(scheduleApi: api);

    await provider.loadWeek(DateTime(2026, 6, 3));
    final ok = await provider.createSlot(
      CreateExcursionScheduleSlotRequest(
        offerId: 'offer-1',
        startAt: createdAt,
        timezone: 'Asia/Almaty',
      ),
    );

    expect(ok, isTrue);
    expect(provider.selectedDate, createdAt.toLocal());
  });
}

ExcursionScheduleSlotVm _slot(
  String id, [
  DateTime? startAt,
  ExcursionScheduleSlotStatus status = ExcursionScheduleSlotStatus.available,
]) {
  final start = startAt ?? DateTime.utc(2026, 6, 3, 8);
  return ExcursionScheduleSlotVm(
    id: id,
    seriesId: 'series-1',
    offerId: 'offer-1',
    productId: 'product-1',
    legacyExcursionId: 'excursion-1',
    startAt: start,
    endAt: start.add(const Duration(hours: 2)),
    timezone: 'Asia/Almaty',
    capacity: 6,
    bookedSeats: 0,
    status: status,
    title: 'Medeu sunrise walk',
  );
}

class _FakeExcursionScheduleApi extends ExcursionScheduleApi {
  _FakeExcursionScheduleApi({
    required this.slots,
    this.createdSlot,
    this.updatedSlot,
    this.closedSlot,
  });

  final List<ExcursionScheduleSlotVm> slots;
  final ExcursionScheduleSlotVm? createdSlot;
  final ExcursionScheduleSlotVm? updatedSlot;
  final ExcursionScheduleSlotVm? closedSlot;
  int loadCalls = 0;
  int publicLoadCalls = 0;
  DateTime? lastFrom;
  DateTime? lastTo;
  String? lastGuideUserId;

  @override
  Future<List<ExcursionScheduleSlotVm>> getGuideSchedule({
    required DateTime from,
    required DateTime to,
  }) async {
    loadCalls++;
    lastFrom = from;
    lastTo = to;
    return slots;
  }

  @override
  Future<List<ExcursionScheduleSlotVm>> getPublicGuideSchedule({
    required String guideUserId,
    required DateTime from,
    required DateTime to,
  }) async {
    publicLoadCalls++;
    lastGuideUserId = guideUserId;
    lastFrom = from;
    lastTo = to;
    return slots;
  }

  @override
  Future<ExcursionScheduleSlotVm> createSlot(
    CreateExcursionScheduleSlotRequest request,
  ) async {
    return createdSlot ?? _slot('created', request.startAt);
  }

  @override
  Future<ExcursionScheduleSlotVm> updateSlot(
    String id,
    UpdateExcursionScheduleSlotRequest request,
  ) async {
    return updatedSlot ?? _slot(id, request.startAt);
  }

  @override
  Future<ExcursionScheduleSlotVm> closeSlot(String id) async {
    return closedSlot ??
        _slot(id, DateTime.utc(2026, 6, 3, 8),
            ExcursionScheduleSlotStatus.closed);
  }

  @override
  Future<void> deleteSlot(String id) async {}
}
