import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

import '../domain/saved_error.dart';
import '../domain/saved_operation.dart';
import '../domain/saved_status.dart';
import '../domain/saved_target.dart';
import '../presentation/state/saved_state_registry.dart';
import 'saved_api.dart';

enum SavedMutationExecutionState {
  pending,
  pendingUnknown,
  succeeded,
  rejected,
  expired,
  superseded,
}

final class SavedMutationExecution {
  const SavedMutationExecution({
    required this.operation,
    required this.state,
    this.serverResult,
    this.cause,
  });

  final SavedMutationOperation operation;
  final SavedMutationExecutionState state;
  final SavedOperationResult? serverResult;
  final Object? cause;
}

abstract interface class SavedItemsRepository {
  SavedStateRegistry get registry;

  int get activeOperationCount;

  SavedMutationOperation? operationFor(SavedTarget target);

  Future<List<SavedTargetSnapshot>> bootstrap(Iterable<SavedTarget> targets);

  Future<SavedMutationExecution> save(
    SavedTarget target, {
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  });

  Future<SavedMutationExecution> unsave(
    SavedTarget target, {
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  });

  Future<SavedMutationExecution> retryActiveMutation(SavedTarget target);

  Future<SavedMutationExecution> resolveActiveMutation(SavedTarget target);

  void clearForLogout();
}

final class SavedRepository implements SavedItemsRepository {
  SavedRepository({
    SavedApiClient? api,
    SavedStateRegistry? registry,
    SavedOperationIdentityFactory? identityFactory,
    this.requestTimeout = const Duration(seconds: 12),
    DateTime Function()? now,
  }) : _api = api ?? SavedApi(),
       registry = registry ?? SavedStateRegistry(),
       _identityFactory =
           identityFactory ?? SecureSavedOperationIdentityFactory(),
       _now = now ?? _utcNow {
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(
        requestTimeout,
        'requestTimeout',
        'Must be positive.',
      );
    }
  }

  static const int _batchSize = SavedApi.maxBatchSize;

  final SavedApiClient _api;
  @override
  final SavedStateRegistry registry;
  final SavedOperationIdentityFactory _identityFactory;
  final DateTime Function() _now;
  final Duration requestTimeout;

  final Map<SavedTarget, SavedMutationOperation> _operations =
      <SavedTarget, SavedMutationOperation>{};
  final Set<String> _mutationRequestsInFlight = <String>{};
  final Set<String> _statusRequestsInFlight = <String>{};
  int _lifecycleEpoch = 0;

  @override
  int get activeOperationCount => _operations.length;

  @override
  SavedMutationOperation? operationFor(SavedTarget target) {
    return _operations[target];
  }

  @override
  Future<List<SavedTargetSnapshot>> bootstrap(
    Iterable<SavedTarget> targets,
  ) async {
    final uniqueTargets = LinkedHashSet<SavedTarget>.of(
      targets,
    ).toList(growable: false);
    if (uniqueTargets.isEmpty) {
      return const <SavedTargetSnapshot>[];
    }

    final epoch = _lifecycleEpoch;
    final hydrated = <SavedTargetSnapshot>[];
    for (var offset = 0; offset < uniqueTargets.length; offset += _batchSize) {
      final end = (offset + _batchSize < uniqueTargets.length)
          ? offset + _batchSize
          : uniqueTargets.length;
      final statuses = await _api
          .getStatuses(uniqueTargets.sublist(offset, end))
          .timeout(requestTimeout);
      if (epoch != _lifecycleEpoch) {
        return const <SavedTargetSnapshot>[];
      }
      registry.hydrateBatch(statuses);
      hydrated.addAll(statuses);
    }
    return List<SavedTargetSnapshot>.unmodifiable(hydrated);
  }

  @override
  Future<SavedMutationExecution> save(
    SavedTarget target, {
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) {
    return _startMutation(target, SavedMutationKind.save, sourceSurface);
  }

  @override
  Future<SavedMutationExecution> unsave(
    SavedTarget target, {
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) {
    return _startMutation(target, SavedMutationKind.unsave, sourceSurface);
  }

  @override
  Future<SavedMutationExecution> retryActiveMutation(SavedTarget target) async {
    final operation = _requireActiveOperation(target);
    if (_mutationRequestsInFlight.contains(operation.identity.operationId)) {
      throw SavedOperationRequestInFlightException(
        operation.identity.operationId,
      );
    }
    registry.markPending(target, operation.identity.operationId);
    return _dispatch(operation, _lifecycleEpoch);
  }

  @override
  Future<SavedMutationExecution> resolveActiveMutation(
    SavedTarget target,
  ) async {
    final operation = _requireActiveOperation(target);
    final operationId = operation.identity.operationId;
    if (!_statusRequestsInFlight.add(operationId)) {
      throw SavedOperationRequestInFlightException(operationId);
    }
    final epoch = _lifecycleEpoch;

    try {
      final result = await _api
          .getOperation(operationId)
          .timeout(requestTimeout);
      return await _handleServerResult(operation, result, epoch);
    } on SavedOperationNotFoundException {
      if (!_isCurrent(operation, epoch)) {
        return _superseded(operation);
      }
      return await _dispatch(operation, epoch);
    } on TimeoutException catch (error) {
      return _markPendingUnknown(operation, epoch, error);
    } on SavedApiException catch (error) {
      if (_shouldRetainForRecovery(error)) {
        return _markPendingUnknown(operation, epoch, error);
      }
      _rejectAfterDefinitiveFailure(operation, epoch);
      rethrow;
    } on DioException catch (error) {
      final apiError = SavedApiException.fromDio(error);
      if (_shouldRetainForRecovery(apiError)) {
        return _markPendingUnknown(operation, epoch, apiError);
      }
      _rejectAfterDefinitiveFailure(operation, epoch);
      rethrow;
    } on FormatException {
      _rejectAfterDefinitiveFailure(operation, epoch);
      rethrow;
    } finally {
      _statusRequestsInFlight.remove(operationId);
    }
  }

  @override
  void clearForLogout() {
    _lifecycleEpoch++;
    _operations.clear();
    _mutationRequestsInFlight.clear();
    _statusRequestsInFlight.clear();
    registry.clearForLogout();
  }

  Future<SavedMutationExecution> _startMutation(
    SavedTarget target,
    SavedMutationKind kind,
    SavedSourceSurface sourceSurface,
  ) {
    if (_operations.containsKey(target) || registry.isLocked(target)) {
      throw SavedTargetLockedException(target);
    }

    final identity = _identityFactory.create();
    final identityCollision = _operations.values.any(
      (operation) =>
          operation.identity.operationId == identity.operationId ||
          operation.identity.idempotencyKey == identity.idempotencyKey,
    );
    if (identityCollision) {
      throw StateError('Saved operation identity collision.');
    }

    final operation = SavedMutationOperation(
      target: target,
      kind: kind,
      identity: identity,
      createdAt: _now().toUtc(),
      sourceSurface: sourceSurface,
    );
    registry.beginMutation(target, identity.operationId);
    _operations[target] = operation;
    return _dispatch(operation, _lifecycleEpoch);
  }

  Future<SavedMutationExecution> _dispatch(
    SavedMutationOperation operation,
    int epoch,
  ) async {
    final operationId = operation.identity.operationId;
    if (!_mutationRequestsInFlight.add(operationId)) {
      throw SavedOperationRequestInFlightException(operationId);
    }

    try {
      final request = switch (operation.kind) {
        SavedMutationKind.save => _api.putSavedItem(
          target: operation.target,
          identity: operation.identity,
          sourceSurface: operation.sourceSurface,
        ),
        SavedMutationKind.unsave => _api.deleteSavedItem(
          target: operation.target,
          identity: operation.identity,
          sourceSurface: operation.sourceSurface,
        ),
      };
      final result = await request.timeout(requestTimeout);
      return await _handleServerResult(operation, result, epoch);
    } on TimeoutException catch (error) {
      return _markPendingUnknown(operation, epoch, error);
    } on SavedApiException catch (error) {
      if (_shouldRetainForRecovery(error)) {
        return _markPendingUnknown(operation, epoch, error);
      }
      _rejectAfterDefinitiveFailure(operation, epoch);
      rethrow;
    } on DioException catch (error) {
      final apiError = SavedApiException.fromDio(error);
      if (_shouldRetainForRecovery(apiError)) {
        return _markPendingUnknown(operation, epoch, apiError);
      }
      _rejectAfterDefinitiveFailure(operation, epoch);
      rethrow;
    } on FormatException {
      _rejectAfterDefinitiveFailure(operation, epoch);
      rethrow;
    } catch (_) {
      _rejectAfterDefinitiveFailure(operation, epoch);
      rethrow;
    } finally {
      _mutationRequestsInFlight.remove(operationId);
    }
  }

  Future<SavedMutationExecution> _handleServerResult(
    SavedMutationOperation operation,
    SavedOperationResult result,
    int epoch,
  ) async {
    if (!_isCurrent(operation, epoch)) {
      return _superseded(operation, result);
    }
    if (result.operationId != operation.identity.operationId) {
      throw const FormatException('Saved operation_id echo mismatch.');
    }
    if (result.operationKind != operation.kind.operationKind) {
      throw const FormatException('Saved operation_kind echo mismatch.');
    }
    final savedItemSnapshot = result.savedItemSnapshot;
    if (savedItemSnapshot != null &&
        savedItemSnapshot.target != operation.target) {
      throw const FormatException('Saved operation target snapshot mismatch.');
    }
    final responseSnapshot = savedItemSnapshot?.toTargetSnapshot();

    switch (result.status) {
      case SavedOperationStatus.pending:
        if (responseSnapshot != null) {
          registry.applySnapshot(responseSnapshot);
        }
        registry.markPending(operation.target, operation.identity.operationId);
        return SavedMutationExecution(
          operation: operation,
          state: SavedMutationExecutionState.pending,
          serverResult: result,
        );
      case SavedOperationStatus.rejected:
        if (responseSnapshot != null) {
          registry.applySnapshot(responseSnapshot);
        }
        registry.rejectMutation(
          operation.target,
          operation.identity.operationId,
        );
        _removeOperation(operation);
        return SavedMutationExecution(
          operation: operation,
          state: SavedMutationExecutionState.rejected,
          serverResult: result,
        );
      case SavedOperationStatus.succeeded:
        return _finishCanonicalTerminal(
          operation,
          result,
          epoch,
          state: SavedMutationExecutionState.succeeded,
          canonicalStateRequired: true,
        );
      case SavedOperationStatus.expired:
        return _finishCanonicalTerminal(
          operation,
          result,
          epoch,
          state: SavedMutationExecutionState.expired,
          canonicalStateRequired: false,
        );
    }
  }

  Future<SavedMutationExecution> _finishCanonicalTerminal(
    SavedMutationOperation operation,
    SavedOperationResult result,
    int epoch, {
    required SavedMutationExecutionState state,
    required bool canonicalStateRequired,
  }) async {
    var snapshot = result.savedItemSnapshot?.toTargetSnapshot();
    Object? refreshError;
    if (snapshot == null) {
      try {
        final statuses = await _api
            .getStatuses(<SavedTarget>[operation.target])
            .timeout(requestTimeout);
        if (!_isCurrent(operation, epoch)) {
          return _superseded(operation, result);
        }
        snapshot = statuses.single;
      } catch (error) {
        refreshError = error;
      }
    }

    if (!_isCurrent(operation, epoch)) {
      return _superseded(operation, result);
    }
    if (snapshot != null && snapshot.target == operation.target) {
      registry.confirmMutation(
        operation.target,
        operation.identity.operationId,
        snapshot,
      );
    } else if (canonicalStateRequired) {
      registry.finishMutationAsUnknown(
        operation.target,
        operation.identity.operationId,
      );
    } else {
      registry.rejectMutation(operation.target, operation.identity.operationId);
    }
    _removeOperation(operation);
    return SavedMutationExecution(
      operation: operation,
      state: state,
      serverResult: result,
      cause: refreshError,
    );
  }

  SavedMutationExecution _markPendingUnknown(
    SavedMutationOperation operation,
    int epoch,
    Object error,
  ) {
    if (!_isCurrent(operation, epoch)) {
      return _superseded(operation);
    }
    registry.markPendingUnknown(
      operation.target,
      operation.identity.operationId,
    );
    return SavedMutationExecution(
      operation: operation,
      state: SavedMutationExecutionState.pendingUnknown,
      cause: error,
    );
  }

  void _rejectAfterDefinitiveFailure(
    SavedMutationOperation operation,
    int epoch,
  ) {
    if (!_isCurrent(operation, epoch)) {
      return;
    }
    registry.rejectMutation(operation.target, operation.identity.operationId);
    _removeOperation(operation);
  }

  SavedMutationOperation _requireActiveOperation(SavedTarget target) {
    final operation = _operations[target];
    if (operation == null) {
      throw SavedOperationUnavailableException(target);
    }
    return operation;
  }

  bool _isCurrent(SavedMutationOperation operation, int epoch) {
    return epoch == _lifecycleEpoch &&
        identical(_operations[operation.target], operation);
  }

  void _removeOperation(SavedMutationOperation operation) {
    if (identical(_operations[operation.target], operation)) {
      _operations.remove(operation.target);
    }
  }

  SavedMutationExecution _superseded(
    SavedMutationOperation operation, [
    SavedOperationResult? result,
  ]) {
    return SavedMutationExecution(
      operation: operation,
      state: SavedMutationExecutionState.superseded,
      serverResult: result,
    );
  }

  bool _shouldRetainForRecovery(SavedApiException error) {
    final cause = error.cause;
    if (cause.response == null) {
      return switch (cause.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError ||
        DioExceptionType.unknown => true,
        DioExceptionType.badResponse ||
        DioExceptionType.cancel ||
        DioExceptionType.badCertificate => false,
      };
    }
    final statusCode = error.statusCode;
    if (statusCode == 408 || (statusCode != null && statusCode >= 500)) {
      return true;
    }
    return statusCode == 409 &&
        error.error?.code == SavedErrorCode.requestInProgress;
  }
}

DateTime _utcNow() => DateTime.now().toUtc();

final class SavedOperationUnavailableException implements Exception {
  const SavedOperationUnavailableException(this.target);

  final SavedTarget target;

  @override
  String toString() => 'No in-memory Saved operation exists for this target.';
}

final class SavedOperationRequestInFlightException implements Exception {
  const SavedOperationRequestInFlightException(this.operationId);

  final String operationId;

  @override
  String toString() => 'A request is already in flight for this operation.';
}
