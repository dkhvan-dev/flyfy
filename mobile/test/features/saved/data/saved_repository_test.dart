import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/saved/data/saved_api.dart';
import 'package:inflap/features/saved/data/saved_repository.dart';
import 'package:inflap/features/saved/domain/saved_error.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_state_registry.dart';

void main() {
  final target = SavedTarget(
    entityType: SavedEntityType.guide,
    entityId: 'guide-1',
  );

  test('timeout keeps PENDING_UNKNOWN and retries with the same key', () async {
    final neverCompletes = Completer<SavedOperationResult>();
    final api = _FakeSavedApi(
      mutationHandlers: <_MutationHandler>[
        (_) => neverCompletes.future,
        (call) async => _operationResult(
          call,
          status: SavedOperationStatus.succeeded,
          currentSnapshot: _savedItemSnapshot(target, saved: true, version: 1),
        ),
      ],
    );
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final repository = SavedRepository(
      api: api,
      registry: registry,
      identityFactory: _FixedIdentityFactory(),
      requestTimeout: const Duration(milliseconds: 5),
    );

    final timedOut = await repository.save(target);

    expect(timedOut.state, SavedMutationExecutionState.pendingUnknown);
    expect(registry.stateFor(target).state, SavedRegistryState.pendingUnknown);
    expect(repository.activeOperationCount, 1);
    expect(registry.isLocked(target), isTrue);

    final retried = await repository.retryActiveMutation(target);

    expect(retried.state, SavedMutationExecutionState.succeeded);
    _expectSameSemanticRequest(api.mutationCalls);
    expect(registry.stateFor(target).state, SavedRegistryState.confirmedSaved);
    expect(repository.activeOperationCount, 0);
  });

  test('SAVED_REQUEST_IN_PROGRESS retains a live same-key operation', () async {
    final api = _FakeSavedApi(
      mutationHandlers: <_MutationHandler>[
        (_) async => throw _apiError(
          409,
          SavedErrorCode.requestInProgress,
          retryable: true,
        ),
        (call) async => _operationResult(
          call,
          status: SavedOperationStatus.succeeded,
          currentSnapshot: _savedItemSnapshot(target, saved: true, version: 2),
        ),
      ],
    );
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final repository = SavedRepository(
      api: api,
      registry: registry,
      identityFactory: _FixedIdentityFactory(),
    );

    final inProgress = await repository.save(target);

    expect(inProgress.state, SavedMutationExecutionState.pendingUnknown);
    expect(repository.activeOperationCount, 1);
    expect(registry.isLocked(target), isTrue);

    final recovered = await repository.retryActiveMutation(target);

    expect(recovered.state, SavedMutationExecutionState.succeeded);
    _expectSameSemanticRequest(api.mutationCalls);
    expect(repository.activeOperationCount, 0);
  });

  test('409 replay/stale and 429 rate rejection are definitive', () async {
    final failures = <(int, SavedErrorCode)>[
      (409, SavedErrorCode.mutationReplayMismatch),
      (409, SavedErrorCode.mutationStale),
      (429, SavedErrorCode.rateLimited),
    ];

    for (final failure in failures) {
      final api = _FakeSavedApi(
        mutationHandlers: <_MutationHandler>[
          (_) async => throw _apiError(failure.$1, failure.$2),
        ],
      );
      final registry = SavedStateRegistry();
      addTearDown(registry.dispose);
      final repository = SavedRepository(
        api: api,
        registry: registry,
        identityFactory: _FixedIdentityFactory(),
      );

      await expectLater(
        repository.save(target),
        throwsA(isA<SavedApiException>()),
        reason: '${failure.$1} ${failure.$2.wireValue}',
      );

      expect(repository.activeOperationCount, 0);
      expect(registry.isLocked(target), isFalse);
      expect(registry.stateFor(target).state, SavedRegistryState.unknown);
    }
  });

  test('ACK-unknown 503 retains the operation for same-key recovery', () async {
    final api = _FakeSavedApi(
      mutationHandlers: <_MutationHandler>[
        (_) async => throw _apiError(
          503,
          SavedErrorCode.temporarilyUnavailable,
          retryable: true,
        ),
        (call) async => _operationResult(
          call,
          status: SavedOperationStatus.succeeded,
          currentSnapshot: _savedItemSnapshot(target, saved: true, version: 3),
        ),
      ],
    );
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final repository = SavedRepository(
      api: api,
      registry: registry,
      identityFactory: _FixedIdentityFactory(),
    );

    expect(
      (await repository.save(target)).state,
      SavedMutationExecutionState.pendingUnknown,
    );
    expect(
      (await repository.retryActiveMutation(target)).state,
      SavedMutationExecutionState.succeeded,
    );
    _expectSameSemanticRequest(api.mutationCalls);
  });

  test('operation NOT_FOUND replays the live semantic request', () async {
    final api = _FakeSavedApi(
      mutationHandlers: <_MutationHandler>[
        (call) async =>
            _operationResult(call, status: SavedOperationStatus.pending),
        (call) async => _operationResult(
          call,
          status: SavedOperationStatus.succeeded,
          currentSnapshot: _savedItemSnapshot(target, saved: true, version: 4),
        ),
      ],
      operationHandler: (operationId) async {
        throw SavedOperationNotFoundException(operationId);
      },
    );
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final repository = SavedRepository(
      api: api,
      registry: registry,
      identityFactory: _FixedIdentityFactory(),
    );

    final pending = await repository.save(target);
    final resolved = await repository.resolveActiveMutation(target);

    expect(pending.state, SavedMutationExecutionState.pending);
    expect(resolved.state, SavedMutationExecutionState.succeeded);
    expect(api.operationStatusCalls, 1);
    _expectSameSemanticRequest(api.mutationCalls);
  });

  test(
    'pending SAVED_ITEM snapshot refreshes baseline without unlock',
    () async {
      final api = _FakeSavedApi(
        mutationHandlers: <_MutationHandler>[
          (call) async => _operationResult(
            call,
            status: SavedOperationStatus.pending,
            currentSnapshot: _savedItemSnapshot(
              target,
              saved: true,
              version: 6,
            ),
          ),
        ],
      );
      final registry = SavedStateRegistry();
      addTearDown(registry.dispose);
      final repository = SavedRepository(
        api: api,
        registry: registry,
        identityFactory: _FixedIdentityFactory(),
      );

      final result = await repository.save(target);
      final state = registry.stateFor(target);

      expect(result.state, SavedMutationExecutionState.pending);
      expect(state.state, SavedRegistryState.pending);
      expect(state.shouldRenderSaved, isTrue);
      expect(state.resourceVersion, 6);
      expect(state.relationshipGeneration, _relationshipGeneration);
      expect(state.isLocked, isTrue);
    },
  );

  test(
    'only SAVED_ITEM current snapshots hydrate target registry state',
    () async {
      final api = _FakeSavedApi(
        mutationHandlers: <_MutationHandler>[
          (call) async => _operationResult(
            call,
            status: SavedOperationStatus.succeeded,
            currentSnapshot: CollectionCurrentSnapshot(
              snapshotVersion: 10,
              snapshotRecordedAt: _recordedAt,
              collectionId: _collectionId,
              lifecycleState: SavedCollectionLifecycleState.deleted,
              metadataVersion: 1,
              lifecycleVersion: 2,
            ),
          ),
        ],
        statuses: <SavedTarget, SavedTargetSnapshot>{
          target: _batchSnapshot(target, saved: false, version: 11),
        },
      );
      final registry = SavedStateRegistry();
      addTearDown(registry.dispose);
      final repository = SavedRepository(
        api: api,
        registry: registry,
        identityFactory: _FixedIdentityFactory(),
      );

      final result = await repository.save(target);

      expect(result.state, SavedMutationExecutionState.succeeded);
      expect(
        result.serverResult?.currentResourceSnapshot,
        isA<CollectionCurrentSnapshot>(),
      );
      expect(api.statusBatchCalls, 1);
      expect(
        registry.stateFor(target).state,
        SavedRegistryState.confirmedUnsaved,
      );
    },
  );

  test(
    'logout prevents a delayed response from repopulating registry',
    () async {
      final response = Completer<SavedOperationResult>();
      final api = _FakeSavedApi(
        mutationHandlers: <_MutationHandler>[(call) => response.future],
      );
      final registry = SavedStateRegistry();
      addTearDown(registry.dispose);
      final repository = SavedRepository(
        api: api,
        registry: registry,
        identityFactory: _FixedIdentityFactory(),
        requestTimeout: const Duration(seconds: 1),
      );

      final pendingFuture = repository.save(target);
      await Future<void>.delayed(Duration.zero);
      final call = api.mutationCalls.single;
      repository.clearForLogout();
      response.complete(
        _operationResult(
          call,
          status: SavedOperationStatus.succeeded,
          currentSnapshot: _savedItemSnapshot(target, saved: true, version: 5),
        ),
      );

      final result = await pendingFuture;

      expect(result.state, SavedMutationExecutionState.superseded);
      expect(repository.activeOperationCount, 0);
      expect(registry.isEmpty, isTrue);
    },
  );

  test(
    'fresh repository has no restart replay and bootstraps batch state',
    () async {
      final api = _FakeSavedApi(
        statuses: <SavedTarget, SavedTargetSnapshot>{
          target: _batchSnapshot(target, saved: true, version: 8),
        },
      );
      final firstRegistry = SavedStateRegistry();
      addTearDown(firstRegistry.dispose);
      final firstRepository = SavedRepository(
        api: api,
        registry: firstRegistry,
        identityFactory: _FixedIdentityFactory(),
      );

      await firstRepository.bootstrap(<SavedTarget>[target]);
      expect(
        firstRegistry.stateFor(target).state,
        SavedRegistryState.confirmedSaved,
      );

      final restartedRegistry = SavedStateRegistry();
      addTearDown(restartedRegistry.dispose);
      final restartedRepository = SavedRepository(
        api: api,
        registry: restartedRegistry,
        identityFactory: _FixedIdentityFactory(),
      );
      expect(restartedRepository.activeOperationCount, 0);
      expect(
        restartedRegistry.stateFor(target).state,
        SavedRegistryState.unknown,
      );

      await restartedRepository.bootstrap(<SavedTarget>[target]);

      expect(api.statusBatchCalls, 2);
      expect(api.operationStatusCalls, 0);
      expect(api.mutationCalls, isEmpty);
      expect(
        restartedRegistry.stateFor(target).state,
        SavedRegistryState.confirmedSaved,
      );
    },
  );
}

typedef _MutationHandler =
    Future<SavedOperationResult> Function(_MutationCall call);

typedef _OperationHandler =
    Future<SavedOperationResult> Function(String operationId);

final class _FakeSavedApi implements SavedApiClient {
  _FakeSavedApi({
    List<_MutationHandler> mutationHandlers = const <_MutationHandler>[],
    this.operationHandler,
    Map<SavedTarget, SavedTargetSnapshot> statuses =
        const <SavedTarget, SavedTargetSnapshot>{},
  }) : mutationHandlers = List<_MutationHandler>.of(mutationHandlers),
       statuses = Map<SavedTarget, SavedTargetSnapshot>.of(statuses);

  final List<_MutationHandler> mutationHandlers;
  final _OperationHandler? operationHandler;
  final Map<SavedTarget, SavedTargetSnapshot> statuses;
  final List<_MutationCall> mutationCalls = <_MutationCall>[];
  int operationStatusCalls = 0;
  int statusBatchCalls = 0;

  @override
  Future<SavedOperationResult> putSavedItem({
    required SavedTarget target,
    required SavedOperationIdentity identity,
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) {
    return _mutate(target, identity, SavedMutationKind.save);
  }

  @override
  Future<SavedOperationResult> deleteSavedItem({
    required SavedTarget target,
    required SavedOperationIdentity identity,
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) {
    return _mutate(target, identity, SavedMutationKind.unsave);
  }

  @override
  Future<List<SavedTargetSnapshot>> getStatuses(
    Iterable<SavedTarget> targets,
  ) async {
    statusBatchCalls++;
    return targets.map((target) => statuses[target]!).toList(growable: false);
  }

  @override
  Future<SavedOperationResult> getOperation(String operationId) {
    operationStatusCalls++;
    final handler = operationHandler;
    if (handler == null) {
      throw StateError('No operation handler configured.');
    }
    return handler(operationId);
  }

  Future<SavedOperationResult> _mutate(
    SavedTarget target,
    SavedOperationIdentity identity,
    SavedMutationKind kind,
  ) {
    final call = _MutationCall(target, identity, kind);
    mutationCalls.add(call);
    if (mutationHandlers.isEmpty) {
      throw StateError('No mutation handler configured.');
    }
    return mutationHandlers.removeAt(0)(call);
  }
}

final class _MutationCall {
  const _MutationCall(this.target, this.identity, this.kind);

  final SavedTarget target;
  final SavedOperationIdentity identity;
  final SavedMutationKind kind;
}

final class _FixedIdentityFactory implements SavedOperationIdentityFactory {
  @override
  SavedOperationIdentity create() {
    return SavedOperationIdentity(
      operationId: '11111111-2222-4333-8444-555555555555',
      idempotencyKey: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    );
  }
}

SavedOperationResult _operationResult(
  _MutationCall call, {
  required SavedOperationStatus status,
  SavedCurrentResourceSnapshot? currentSnapshot,
}) {
  final outcome = switch (status) {
    SavedOperationStatus.pending => SavedOperationOutcome.pending,
    SavedOperationStatus.succeeded => SavedOperationOutcome.applied,
    SavedOperationStatus.rejected => SavedOperationOutcome.rejected,
    SavedOperationStatus.expired => SavedOperationOutcome.expired,
  };
  return SavedOperationResult(
    operationId: call.identity.operationId,
    operationKind: call.kind.operationKind,
    status: status,
    outcome: outcome,
    commitDeadline: DateTime.utc(2026, 7, 16, 10, 0, 15),
    refreshScope: SavedRefreshScope.savedItems,
    appliedResourceVersions: AppliedResourceVersions(),
    resultRecordedAt: _recordedAt,
    operationError: status == SavedOperationStatus.rejected
        ? SavedOperationError(
            code: SavedErrorCode.targetUnavailable,
            retryable: false,
          )
        : null,
    currentResourceSnapshot: currentSnapshot,
  );
}

SavedItemCurrentSnapshot _savedItemSnapshot(
  SavedTarget target, {
  required bool saved,
  required int version,
}) {
  return SavedItemCurrentSnapshot(
    snapshotVersion: version,
    snapshotRecordedAt: _recordedAt,
    target: target,
    savedState: saved
        ? SavedConfirmation.saved
        : SavedConfirmation.confirmedUnsaved,
    relationship: saved
        ? ExistingRelationshipSnapshot(
            state: SavedRelationshipState.active,
            generation: _relationshipGeneration,
            version: version,
          )
        : const AbsentRelationshipSnapshot(),
    effectiveCollectionCount: 0,
  );
}

SavedTargetSnapshot _batchSnapshot(
  SavedTarget target, {
  required bool saved,
  required int version,
}) {
  return SavedTargetSnapshot(
    target: target,
    savedState: saved
        ? SavedConfirmation.saved
        : SavedConfirmation.confirmedUnsaved,
    eligibility: SavedEligibility.eligible,
    effectiveCollectionCount: 0,
    relationshipGeneration: saved ? _relationshipGeneration : null,
    resourceVersion: version,
  );
}

SavedApiException _apiError(
  int statusCode,
  SavedErrorCode code, {
  bool retryable = false,
}) {
  final options = RequestOptions(path: '/users/me/saved-items/test');
  return SavedApiException.fromDio(
    DioException(
      requestOptions: options,
      response: Response<Map<String, Object?>>(
        requestOptions: options,
        statusCode: statusCode,
        data: <String, Object?>{'code': code.wireValue, 'retryable': retryable},
      ),
      type: DioExceptionType.badResponse,
    ),
  );
}

void _expectSameSemanticRequest(List<_MutationCall> calls) {
  expect(calls, hasLength(2));
  expect(calls[1].identity.operationId, calls[0].identity.operationId);
  expect(calls[1].identity.idempotencyKey, calls[0].identity.idempotencyKey);
  expect(calls[1].kind, calls[0].kind);
  expect(calls[1].target, calls[0].target);
}

final DateTime _recordedAt = DateTime.utc(2026, 7, 16, 10, 0, 1);
const String _relationshipGeneration = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
const String _collectionId = '22222222-3333-4444-8555-666666666666';
