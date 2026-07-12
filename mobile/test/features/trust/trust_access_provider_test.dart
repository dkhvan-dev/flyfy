import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/trust/data/trust_access_api.dart';
import 'package:inflap/features/trust/providers/trust_access_provider.dart';

void main() {
  test('trust snapshot parses supported restrictions and ignores unknowns', () {
    final snapshot = TrustAccessSnapshot.fromJson({
      'profile': {'status': 'restricted'},
      'activeRestrictions': [
        {
          'restrictionId': 'restriction-1',
          'restrictionCode': 'activity_creation',
          'reasonCode': 'staff_restriction',
          'expiresAt': '2026-07-20T12:00:00Z',
        },
        {
          'restrictionId': 'restriction-unknown',
          'restrictionCode': 'FUTURE_CAPABILITY',
        },
      ],
    });

    expect(snapshot.status, 'RESTRICTED');
    expect(snapshot.activeRestrictions, hasLength(1));
    expect(
      snapshot.activeRestrictions.single.code,
      TrustRestrictionCode.activityCreation,
    );
    expect(
      snapshot.activeRestrictions.single.expiresAt,
      DateTime.utc(2026, 7, 20, 12),
    );
  });

  test('provider maps restriction codes to capabilities', () async {
    final api = _FakeTrustAccessApi([
      _snapshot(TrustRestrictionCode.activityCreation),
    ]);
    final provider = TrustAccessProvider(
      api: api,
      refreshInterval: const Duration(hours: 1),
    );

    await provider.refresh(force: true);

    expect(provider.state, TrustAccessState.ready);
    expect(provider.isRestricted(TrustCapability.createActivity), isTrue);
    expect(provider.isRestricted(TrustCapability.publishTour), isFalse);
    expect(api.calls, 1);

    await provider.refresh();
    expect(api.calls, 1, reason: 'fresh snapshots should respect the TTL');
  });

  test('account suspension restricts every exposed capability', () async {
    final provider = TrustAccessProvider(
      api: _FakeTrustAccessApi([
        _snapshot(TrustRestrictionCode.accountSuspension),
      ]),
    );

    await provider.refresh(force: true);

    for (final capability in TrustCapability.values) {
      expect(
        provider.isRestricted(capability),
        isTrue,
        reason: '$capability must be blocked by account suspension',
      );
    }
  });

  test(
    'restriction push forces refresh while unrelated push does not',
    () async {
      final api = _FakeTrustAccessApi([
        const TrustAccessSnapshot(status: 'ACTIVE', activeRestrictions: []),
        _snapshot(TrustRestrictionCode.chat),
      ]);
      final provider = TrustAccessProvider(
        api: api,
        refreshInterval: const Duration(hours: 1),
      );
      await provider.refresh(force: true);

      await provider.handlePushData({'adminEvent': 'booking_confirmed'});
      expect(api.calls, 1);

      await provider.handlePushData({
        'adminEvent': 'user_restriction_created',
        'restrictionCode': 'CHAT',
      });
      expect(api.calls, 2);
      expect(provider.isRestricted(TrustCapability.sendChatMessage), isTrue);
    },
  );

  test('forced refresh is queued behind an in-flight request', () async {
    final firstResponse = Completer<TrustAccessSnapshot>();
    final api = _DeferredTrustAccessApi(
      firstResponse,
      _snapshot(TrustRestrictionCode.payout),
    );
    final provider = TrustAccessProvider(api: api);

    final initialRefresh = provider.refresh(force: true);
    await Future<void>.delayed(Duration.zero);
    final pushRefresh = provider.handlePushData({
      'adminEvent': 'user_restriction_created',
    });
    firstResponse.complete(
      const TrustAccessSnapshot(status: 'ACTIVE', activeRestrictions: []),
    );
    await initialRefresh;
    await pushRefresh;

    expect(api.calls, 2);
    expect(provider.isRestricted(TrustCapability.requestPayout), isTrue);
  });

  test('clear discards a response from the previous session', () async {
    final response = Completer<TrustAccessSnapshot>();
    final api = _DeferredTrustAccessApi(
      response,
      const TrustAccessSnapshot(status: 'ACTIVE', activeRestrictions: []),
    );
    final provider = TrustAccessProvider(api: api);

    final refresh = provider.refresh(force: true);
    provider.clear();
    response.complete(_snapshot(TrustRestrictionCode.accountSuspension));
    await refresh;

    expect(provider.state, TrustAccessState.initial);
    expect(provider.activeRestrictions, isEmpty);
  });
}

TrustAccessSnapshot _snapshot(TrustRestrictionCode code) {
  return TrustAccessSnapshot(
    status: 'RESTRICTED',
    activeRestrictions: [
      TrustActiveRestriction(
        id: 'restriction-${code.wireName}',
        code: code,
        reasonCode: 'staff_restriction',
      ),
    ],
  );
}

class _FakeTrustAccessApi implements TrustAccessApi {
  _FakeTrustAccessApi(this.responses);

  final List<TrustAccessSnapshot> responses;
  int calls = 0;

  @override
  Future<TrustAccessSnapshot> getMyTrustAccess() async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls += 1;
    return responses[index];
  }
}

class _DeferredTrustAccessApi implements TrustAccessApi {
  _DeferredTrustAccessApi(this.firstResponse, this.nextResponse);

  final Completer<TrustAccessSnapshot> firstResponse;
  final TrustAccessSnapshot nextResponse;
  int calls = 0;

  @override
  Future<TrustAccessSnapshot> getMyTrustAccess() {
    calls += 1;
    if (calls == 1) return firstResponse.future;
    return Future.value(nextResponse);
  }
}
