import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/saved/data/saved_api.dart';
import 'package:inflap/features/saved/data/saved_browse_api.dart';
import 'package:inflap/features/saved/data/saved_feature_repository.dart';
import 'package:inflap/features/saved/data/saved_repository.dart';
import 'package:inflap/features/saved/domain/saved_browse_models.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_state_registry.dart';

import '../support/saved_test_fakes.dart';

void main() {
  test(
    'facade delegates batch bootstrap and live mutations to one repository',
    () async {
      final itemsRepository = _RecordingSavedItemsRepository();
      addTearDown(itemsRepository.registry.dispose);
      final repository = SavedFeatureRepositoryImpl(
        itemsRepository: itemsRepository,
      );
      final activity = SavedTarget(
        entityType: SavedEntityType.activity,
        entityId: 'activity-1',
      );
      final guide = SavedTarget(
        entityType: SavedEntityType.guide,
        entityId: 'guide-1',
      );

      final statuses = await repository.bootstrapTargetStatuses(<SavedTarget>[
        activity,
        guide,
      ]);
      await repository.save(activity, sourceSurface: SavedSourceSurface.card);
      await repository.unsave(guide, sourceSurface: SavedSourceSurface.detail);
      await repository.resolveLiveMutation(activity);

      expect(identical(repository.registry, itemsRepository.registry), isTrue);
      expect(statuses.map((status) => status.target), <SavedTarget>[
        activity,
        guide,
      ]);
      expect(itemsRepository.bootstrapCalls.single, <SavedTarget>[
        activity,
        guide,
      ]);
      expect(itemsRepository.saveCalls.single.target, activity);
      expect(
        itemsRepository.saveCalls.single.sourceSurface,
        SavedSourceSurface.card,
      );
      expect(itemsRepository.unsaveCalls.single.target, guide);
      expect(
        itemsRepository.unsaveCalls.single.sourceSurface,
        SavedSourceSurface.detail,
      );
      expect(itemsRepository.resolveCalls, <SavedTarget>[activity]);
    },
  );

  test('facade logout clears the same live repository and registry', () {
    final itemsRepository = _RecordingSavedItemsRepository();
    addTearDown(itemsRepository.registry.dispose);
    final repository = SavedFeatureRepositoryImpl(
      itemsRepository: itemsRepository,
    );

    repository.clearForLogout();

    expect(itemsRepository.clearCount, 1);
    expect(repository.registry, isEmpty);
  });

  test(
    'recoverable 503 resolves the accepted command by operation id',
    () async {
      final itemsRepository = _RecordingSavedItemsRepository();
      addTearDown(itemsRepository.registry.dispose);
      final api = _RecoveringSavedBrowseApi(
        operation: operationResult(
          kind: SavedOperationKind.setTargetCollections,
        ),
      );
      final repository = SavedFeatureRepositoryImpl(
        browseApi: api,
        itemsRepository: itemsRepository,
        identityFactory: _FixedIdentityFactory(),
      );
      final current = targetCollections(
        SavedTarget(
          entityType: SavedEntityType.activity,
          entityId: 'activity-1',
        ),
      );

      final result = await repository.replaceTargetCollections(
        current: current,
        desiredCollectionIds: const <String>[collectionB],
        sourceSurface: SavedSourceSurface.savedAll,
      );

      expect(result.state, SavedCommandExecutionState.succeeded);
      expect(api.replaceCalls, 1);
      expect(api.operationStatusCalls, 1);
      expect(
        repository.isCommandActive(SavedCommandKey.assignment(current.target)),
        isFalse,
      );
    },
  );

  test('pending command stops polling and releases its UI lock', () async {
    final itemsRepository = _RecordingSavedItemsRepository();
    addTearDown(itemsRepository.registry.dispose);
    final deadline = DateTime.utc(2026, 7, 16, 10, 0, 15);
    final api = _RecoveringSavedBrowseApi(
      operation: _pendingCollectionOperation(deadline),
    );
    final repository = SavedFeatureRepositoryImpl(
      browseApi: api,
      itemsRepository: itemsRepository,
      identityFactory: _FixedIdentityFactory(),
      maxPollAttempts: 3,
      delay: (_) async {},
    );
    final current = targetCollections(
      SavedTarget(entityType: SavedEntityType.activity, entityId: 'activity-1'),
    );

    final result = await repository.replaceTargetCollections(
      current: current,
      desiredCollectionIds: const <String>[collectionB],
      sourceSurface: SavedSourceSurface.savedAll,
    );

    expect(result.state, SavedCommandExecutionState.pendingUnknown);
    expect(result.serverResult?.commitDeadline, deadline);
    expect(api.operationStatusCalls, 4);
    expect(
      repository.isCommandActive(SavedCommandKey.assignment(current.target)),
      isFalse,
    );
  });
}

final class _RecoveringSavedBrowseApi implements SavedBrowseApiClient {
  _RecoveringSavedBrowseApi({required this.operation});

  final SavedOperationResult operation;
  int replaceCalls = 0;
  int operationStatusCalls = 0;

  @override
  Future<SavedOperationResult> replaceTargetCollections({
    required SavedTargetCollectionsSnapshot current,
    required Iterable<String> desiredCollectionIds,
    SavedNewCollection? newCollection,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  }) async {
    replaceCalls++;
    throw _temporarilyUnavailable();
  }

  @override
  Future<SavedOperationResult> getOperation(String operationId) async {
    operationStatusCalls++;
    expect(operationId, operation.operationId);
    return operation;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}

final class _FixedIdentityFactory implements SavedOperationIdentityFactory {
  @override
  SavedOperationIdentity create() {
    return SavedOperationIdentity(
      operationId: operationId,
      idempotencyKey: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    );
  }
}

SavedApiException _temporarilyUnavailable() {
  final request = RequestOptions(
    path: '/users/me/saved-items/ACTIVITY/activity-1/collections',
  );
  return SavedApiException.fromDio(
    DioException(
      requestOptions: request,
      response: Response<Object?>(
        requestOptions: request,
        statusCode: 503,
        data: const <String, Object?>{
          'code': 'SAVED_TEMPORARILY_UNAVAILABLE',
          'retryable': true,
        },
      ),
      type: DioExceptionType.badResponse,
    ),
  );
}

SavedOperationResult _pendingCollectionOperation(DateTime deadline) {
  return SavedOperationResult(
    operationId: operationId,
    operationKind: SavedOperationKind.setTargetCollections,
    status: SavedOperationStatus.pending,
    outcome: SavedOperationOutcome.pending,
    commitDeadline: deadline,
    refreshScope: SavedRefreshScope.none,
    appliedResourceVersions: AppliedResourceVersions(),
    resultRecordedAt: deadline.subtract(const Duration(seconds: 14)),
  );
}

final class _RecordingSavedItemsRepository implements SavedItemsRepository {
  @override
  final SavedStateRegistry registry = SavedStateRegistry();

  final List<List<SavedTarget>> bootstrapCalls = <List<SavedTarget>>[];
  final List<SavedMutationCall> saveCalls = <SavedMutationCall>[];
  final List<SavedMutationCall> unsaveCalls = <SavedMutationCall>[];
  final List<SavedTarget> resolveCalls = <SavedTarget>[];
  int clearCount = 0;

  @override
  int get activeOperationCount => 0;

  @override
  SavedMutationOperation? operationFor(SavedTarget target) => null;

  @override
  Future<List<SavedTargetSnapshot>> bootstrap(
    Iterable<SavedTarget> targets,
  ) async {
    final requested = List<SavedTarget>.unmodifiable(targets);
    bootstrapCalls.add(requested);
    return requested
        .map(
          (target) => SavedTargetSnapshot(
            target: target,
            savedState: SavedConfirmation.confirmedUnsaved,
            eligibility: SavedEligibility.eligible,
            effectiveCollectionCount: 0,
            resourceVersion: 1,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<SavedMutationExecution> save(
    SavedTarget target, {
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) async {
    saveCalls.add(
      SavedMutationCall(target: target, sourceSurface: sourceSurface),
    );
    return successfulMutationExecution(
      target,
      kind: SavedMutationKind.save,
      sourceSurface: sourceSurface,
    );
  }

  @override
  Future<SavedMutationExecution> unsave(
    SavedTarget target, {
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) async {
    unsaveCalls.add(
      SavedMutationCall(target: target, sourceSurface: sourceSurface),
    );
    return successfulMutationExecution(
      target,
      kind: SavedMutationKind.unsave,
      sourceSurface: sourceSurface,
    );
  }

  @override
  Future<SavedMutationExecution> retryActiveMutation(SavedTarget target) {
    throw UnimplementedError();
  }

  @override
  Future<SavedMutationExecution> resolveActiveMutation(
    SavedTarget target,
  ) async {
    resolveCalls.add(target);
    return successfulMutationExecution(
      target,
      kind: SavedMutationKind.save,
      sourceSurface: SavedSourceSurface.card,
    );
  }

  @override
  void clearForLogout() {
    clearCount++;
    registry.clearForLogout();
  }
}
