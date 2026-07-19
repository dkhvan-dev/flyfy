import 'dart:async';

import 'package:dio/dio.dart';

import '../domain/saved_browse_models.dart';
import '../domain/saved_error.dart';
import '../domain/saved_operation.dart';
import '../domain/saved_status.dart';
import '../domain/saved_target.dart';
import '../presentation/state/saved_state_registry.dart';
import 'saved_api.dart';
import 'saved_browse_api.dart';
import 'saved_repository.dart';

enum SavedCommandExecutionState {
  succeeded,
  rejected,
  expired,
  pendingUnknown,
  superseded,
}

final class SavedCommandExecution {
  const SavedCommandExecution({
    required this.key,
    required this.state,
    this.serverResult,
    this.cause,
  });

  final SavedCommandKey key;
  final SavedCommandExecutionState state;
  final SavedOperationResult? serverResult;
  final Object? cause;

  bool get isApplied =>
      state == SavedCommandExecutionState.succeeded &&
      serverResult?.outcome == SavedOperationOutcome.applied;
}

final class SavedCommandKey {
  const SavedCommandKey._(this.value);

  factory SavedCommandKey.createCollection() {
    return const SavedCommandKey._('collection:create');
  }

  factory SavedCommandKey.collection(String collectionId) {
    return SavedCommandKey._('collection:$collectionId');
  }

  factory SavedCommandKey.assignment(SavedTarget target) {
    return SavedCommandKey._(
      'assignment:${target.entityType.wireValue}:${target.entityId}',
    );
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCommandKey && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

abstract interface class SavedFeatureRepository {
  SavedStateRegistry get registry;

  Future<SavedCapabilities> getCapabilities({CancelToken? cancelToken});

  Future<SavedPage<SavedListItem>> listItems({
    SavedEntityType? entityType,
    String? collectionId,
    String? cursor,
    CancelToken? cancelToken,
  });

  Future<SavedPage<SavedSearchItem>> searchItems({
    required String search,
    SavedEntityType? entityType,
    String? collectionId,
    String? cursor,
    CancelToken? cancelToken,
  });

  Future<SavedCollectionsList> listCollections({CancelToken? cancelToken});

  Future<SavedCollectionDetail> getCollection(
    String collectionId, {
    CancelToken? cancelToken,
  });

  Future<SavedTargetCollectionsSnapshot> getTargetCollections(
    SavedTarget target, {
    CancelToken? cancelToken,
  });

  Future<List<SavedTargetSnapshot>> bootstrapTargetStatuses(
    Iterable<SavedTarget> targets,
  );

  Future<SavedMutationExecution> save(
    SavedTarget target, {
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedMutationExecution> unsave(
    SavedTarget target, {
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedMutationExecution> resolveLiveMutation(SavedTarget target);

  Future<SavedCommandExecution> replaceTargetCollections({
    required SavedTargetCollectionsSnapshot current,
    required Iterable<String> desiredCollectionIds,
    String? newCollectionTitle,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedCommandExecution> createCollection({
    required String title,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedCommandExecution> renameCollection({
    required SavedCollectionRecord collection,
    required String title,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedCommandExecution> deleteCollection({
    required SavedCollectionRecord collection,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedCommandExecution> retryCommand(SavedCommandKey key);

  bool isCommandActive(SavedCommandKey key);

  void clearForLogout();
}

final class SavedFeatureRepositoryImpl implements SavedFeatureRepository {
  SavedFeatureRepositoryImpl({
    SavedBrowseApiClient? browseApi,
    SavedItemsRepository? itemsRepository,
    SavedOperationIdentityFactory? identityFactory,
    this.requestTimeout = const Duration(seconds: 12),
    this.pollInterval = const Duration(seconds: 1),
    this.maxPollDuration = const Duration(seconds: 17),
    this.maxPollAttempts = 17,
    Future<void> Function(Duration duration)? delay,
  }) : _browseApi = browseApi ?? SavedBrowseApi(),
       _itemsRepository = itemsRepository ?? SavedRepository(),
       _identityFactory =
           identityFactory ?? SecureSavedOperationIdentityFactory(),
       _delay = delay ?? Future<void>.delayed {
    if (requestTimeout <= Duration.zero ||
        pollInterval <= Duration.zero ||
        maxPollDuration <= Duration.zero ||
        maxPollAttempts < 1) {
      throw ArgumentError('Saved repository durations must be positive.');
    }
  }

  final SavedBrowseApiClient _browseApi;
  final SavedItemsRepository _itemsRepository;
  final SavedOperationIdentityFactory _identityFactory;
  final Future<void> Function(Duration duration) _delay;
  final Duration requestTimeout;
  final Duration pollInterval;
  final Duration maxPollDuration;
  final int maxPollAttempts;

  final Map<SavedCommandKey, _ActiveSavedCommand> _commands =
      <SavedCommandKey, _ActiveSavedCommand>{};
  int _lifecycleEpoch = 0;

  @override
  SavedStateRegistry get registry => _itemsRepository.registry;

  @override
  Future<SavedCapabilities> getCapabilities({CancelToken? cancelToken}) {
    return _browseApi.getCapabilities(cancelToken: cancelToken);
  }

  @override
  Future<SavedPage<SavedListItem>> listItems({
    SavedEntityType? entityType,
    String? collectionId,
    String? cursor,
    CancelToken? cancelToken,
  }) {
    return _browseApi.listItems(
      entityType: entityType,
      collectionId: collectionId,
      cursor: cursor,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<SavedPage<SavedSearchItem>> searchItems({
    required String search,
    SavedEntityType? entityType,
    String? collectionId,
    String? cursor,
    CancelToken? cancelToken,
  }) {
    return _browseApi.searchItems(
      search: search,
      entityType: entityType,
      collectionId: collectionId,
      cursor: cursor,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<SavedCollectionsList> listCollections({CancelToken? cancelToken}) {
    return _browseApi.listCollections(cancelToken: cancelToken);
  }

  @override
  Future<SavedCollectionDetail> getCollection(
    String collectionId, {
    CancelToken? cancelToken,
  }) {
    return _browseApi.getCollection(collectionId, cancelToken: cancelToken);
  }

  @override
  Future<SavedTargetCollectionsSnapshot> getTargetCollections(
    SavedTarget target, {
    CancelToken? cancelToken,
  }) {
    return _browseApi.getTargetCollections(target, cancelToken: cancelToken);
  }

  @override
  Future<List<SavedTargetSnapshot>> bootstrapTargetStatuses(
    Iterable<SavedTarget> targets,
  ) {
    return _itemsRepository.bootstrap(targets);
  }

  @override
  Future<SavedMutationExecution> save(
    SavedTarget target, {
    required SavedSourceSurface sourceSurface,
  }) {
    return _itemsRepository.save(target, sourceSurface: sourceSurface);
  }

  @override
  Future<SavedMutationExecution> unsave(
    SavedTarget target, {
    required SavedSourceSurface sourceSurface,
  }) {
    return _itemsRepository.unsave(target, sourceSurface: sourceSurface);
  }

  @override
  Future<SavedMutationExecution> resolveLiveMutation(SavedTarget target) {
    return _itemsRepository.resolveActiveMutation(target);
  }

  @override
  Future<SavedCommandExecution> replaceTargetCollections({
    required SavedTargetCollectionsSnapshot current,
    required Iterable<String> desiredCollectionIds,
    String? newCollectionTitle,
    required SavedSourceSurface sourceSurface,
  }) {
    final identity = _identityFactory.create();
    final desiredIds = List<String>.unmodifiable(desiredCollectionIds);
    SavedNewCollection? newCollection;
    if (newCollectionTitle != null) {
      final creationIdentity = _identityFactory.create();
      newCollection = SavedNewCollection(
        clientCreationId: creationIdentity.operationId,
        title: newCollectionTitle,
      );
    }
    final key = SavedCommandKey.assignment(current.target);
    return _startCommand(
      _ActiveSavedCommand(
        key: key,
        identity: identity,
        kind: SavedOperationKind.setTargetCollections,
        dispatch: () => _browseApi.replaceTargetCollections(
          current: current,
          desiredCollectionIds: desiredIds,
          newCollection: newCollection,
          identity: identity,
          sourceSurface: sourceSurface,
        ),
      ),
    );
  }

  @override
  Future<SavedCommandExecution> createCollection({
    required String title,
    required SavedSourceSurface sourceSurface,
  }) {
    final identity = _identityFactory.create();
    final creationIdentity = _identityFactory.create();
    final collection = SavedNewCollection(
      clientCreationId: creationIdentity.operationId,
      title: title,
    );
    return _startCommand(
      _ActiveSavedCommand(
        key: SavedCommandKey.createCollection(),
        identity: identity,
        kind: SavedOperationKind.createCollection,
        dispatch: () => _browseApi.createCollection(
          collection: collection,
          identity: identity,
          sourceSurface: sourceSurface,
        ),
      ),
    );
  }

  @override
  Future<SavedCommandExecution> renameCollection({
    required SavedCollectionRecord collection,
    required String title,
    required SavedSourceSurface sourceSurface,
  }) {
    final identity = _identityFactory.create();
    return _startCommand(
      _ActiveSavedCommand(
        key: SavedCommandKey.collection(collection.collectionId),
        identity: identity,
        kind: SavedOperationKind.renameCollection,
        dispatch: () => _browseApi.renameCollection(
          collection: collection,
          title: title,
          identity: identity,
          sourceSurface: sourceSurface,
        ),
      ),
    );
  }

  @override
  Future<SavedCommandExecution> deleteCollection({
    required SavedCollectionRecord collection,
    required SavedSourceSurface sourceSurface,
  }) {
    final identity = _identityFactory.create();
    return _startCommand(
      _ActiveSavedCommand(
        key: SavedCommandKey.collection(collection.collectionId),
        identity: identity,
        kind: SavedOperationKind.deleteCollection,
        dispatch: () => _browseApi.deleteCollection(
          collection: collection,
          identity: identity,
          sourceSurface: sourceSurface,
        ),
      ),
    );
  }

  @override
  Future<SavedCommandExecution> retryCommand(SavedCommandKey key) {
    final command = _commands[key];
    if (command == null) {
      throw StateError('No active Saved command exists for this resource.');
    }
    return _drive(command, _lifecycleEpoch, resolveFirst: true);
  }

  @override
  bool isCommandActive(SavedCommandKey key) => _commands.containsKey(key);

  @override
  void clearForLogout() {
    _lifecycleEpoch++;
    _commands.clear();
    _itemsRepository.clearForLogout();
  }

  Future<SavedCommandExecution> _startCommand(_ActiveSavedCommand command) {
    if (_commands.containsKey(command.key)) {
      throw StateError('A Saved command is already active for this resource.');
    }
    _commands[command.key] = command;
    return _drive(command, _lifecycleEpoch);
  }

  Future<SavedCommandExecution> _drive(
    _ActiveSavedCommand command,
    int epoch, {
    bool resolveFirst = false,
  }) async {
    if (command.inFlight) {
      throw StateError('The Saved command request is already in flight.');
    }
    command.inFlight = true;
    try {
      var result = resolveFirst
          ? await _resolveOrRepeat(command)
          : await command.dispatch().timeout(requestTimeout);
      return await _settleResult(command, epoch, result);
    } on TimeoutException catch (error) {
      return await _recoverAfterAmbiguousFailure(command, epoch, error);
    } on SavedOperationNotFoundException {
      try {
        final result = await command.dispatch().timeout(requestTimeout);
        return await _settleResult(command, epoch, result);
      } on Object catch (error) {
        return await _handleDispatchError(command, epoch, error);
      }
    } on Object catch (error) {
      return await _handleDispatchError(command, epoch, error);
    } finally {
      command.inFlight = false;
    }
  }

  Future<SavedCommandExecution> _settleResult(
    _ActiveSavedCommand command,
    int epoch,
    SavedOperationResult initial,
  ) async {
    final commitDeadline = initial.commitDeadline;
    _validateCommandResult(
      command,
      initial,
      expectedCommitDeadline: commitDeadline,
    );
    var result = initial;
    var pollAttempts = 0;
    final pollBudget = _pollBudget(initial);
    final stopwatch = Stopwatch()..start();
    while (_isCurrent(command, epoch) &&
        result.status == SavedOperationStatus.pending &&
        pollAttempts < maxPollAttempts &&
        stopwatch.elapsed < pollBudget) {
      final remainingBudget = pollBudget - stopwatch.elapsed;
      await _delay(
        pollInterval < remainingBudget ? pollInterval : remainingBudget,
      );
      if (!_isCurrent(command, epoch)) {
        return _superseded(command);
      }
      result = await _resolveOrRepeat(command);
      pollAttempts++;
      _validateCommandResult(
        command,
        result,
        expectedCommitDeadline: commitDeadline,
      );
    }
    stopwatch.stop();
    if (!_isCurrent(command, epoch)) {
      return _superseded(command, result);
    }
    final state = switch (result.status) {
      SavedOperationStatus.succeeded => SavedCommandExecutionState.succeeded,
      SavedOperationStatus.rejected => SavedCommandExecutionState.rejected,
      SavedOperationStatus.expired => SavedCommandExecutionState.expired,
      SavedOperationStatus.pending => SavedCommandExecutionState.pendingUnknown,
    };
    _commands.remove(command.key);
    return SavedCommandExecution(
      key: command.key,
      state: state,
      serverResult: result,
    );
  }

  Duration _pollBudget(SavedOperationResult result) {
    final serverRemaining = result.commitDeadline.difference(
      result.resultRecordedAt,
    );
    if (serverRemaining <= Duration.zero) return Duration.zero;
    const deadlineGrace = Duration(seconds: 2);
    final budget = serverRemaining + deadlineGrace;
    return budget < maxPollDuration ? budget : maxPollDuration;
  }

  void _validateCommandResult(
    _ActiveSavedCommand command,
    SavedOperationResult result, {
    required DateTime expectedCommitDeadline,
  }) {
    if (result.operationId != command.identity.operationId ||
        result.operationKind != command.kind) {
      throw const FormatException('Saved command operation echo mismatch.');
    }
    if (result.commitDeadline != expectedCommitDeadline) {
      throw const FormatException('Saved command commit deadline changed.');
    }
  }

  Future<SavedOperationResult> _resolveOrRepeat(
    _ActiveSavedCommand command,
  ) async {
    try {
      return await _browseApi
          .getOperation(command.identity.operationId)
          .timeout(requestTimeout);
    } on SavedOperationNotFoundException {
      return command.dispatch().timeout(requestTimeout);
    }
  }

  Future<SavedCommandExecution> _handleDispatchError(
    _ActiveSavedCommand command,
    int epoch,
    Object error,
  ) async {
    if (error is SavedApiException && _isRecoverable(error)) {
      return _recoverAfterAmbiguousFailure(command, epoch, error);
    }
    if (error is DioException) {
      final apiError = SavedApiException.fromDio(error);
      if (_isRecoverable(apiError)) {
        return _recoverAfterAmbiguousFailure(command, epoch, apiError);
      }
    }
    if (_isCurrent(command, epoch)) {
      _commands.remove(command.key);
    }
    Error.throwWithStackTrace(error, StackTrace.current);
  }

  Future<SavedCommandExecution> _recoverAfterAmbiguousFailure(
    _ActiveSavedCommand command,
    int epoch,
    Object cause,
  ) async {
    try {
      final result = await _browseApi
          .getOperation(command.identity.operationId)
          .timeout(requestTimeout);
      return await _settleResult(command, epoch, result);
    } on SavedOperationNotFoundException {
      try {
        final result = await command.dispatch().timeout(requestTimeout);
        return await _settleResult(command, epoch, result);
      } on Object catch (error) {
        if (_isRecoverableError(error)) {
          return _pendingUnknown(command, epoch, error);
        }
        if (_isCurrent(command, epoch)) {
          _commands.remove(command.key);
        }
        Error.throwWithStackTrace(error, StackTrace.current);
      }
    } on Object catch (error) {
      if (_isRecoverableError(error)) {
        return _pendingUnknown(command, epoch, cause);
      }
      if (_isCurrent(command, epoch)) {
        _commands.remove(command.key);
      }
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  bool _isRecoverableError(Object error) {
    if (error is TimeoutException) return true;
    if (error is SavedApiException) return _isRecoverable(error);
    return error is DioException &&
        _isRecoverable(SavedApiException.fromDio(error));
  }

  SavedCommandExecution _pendingUnknown(
    _ActiveSavedCommand command,
    int epoch,
    Object error,
  ) {
    if (!_isCurrent(command, epoch)) return _superseded(command);
    return SavedCommandExecution(
      key: command.key,
      state: SavedCommandExecutionState.pendingUnknown,
      cause: error,
    );
  }

  bool _isCurrent(_ActiveSavedCommand command, int epoch) {
    return epoch == _lifecycleEpoch &&
        identical(_commands[command.key], command);
  }

  SavedCommandExecution _superseded(
    _ActiveSavedCommand command, [
    SavedOperationResult? result,
  ]) {
    return SavedCommandExecution(
      key: command.key,
      state: SavedCommandExecutionState.superseded,
      serverResult: result,
    );
  }

  bool _isRecoverable(SavedApiException error) {
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

final class _ActiveSavedCommand {
  _ActiveSavedCommand({
    required this.key,
    required this.identity,
    required this.kind,
    required this.dispatch,
  });

  final SavedCommandKey key;
  final SavedOperationIdentity identity;
  final SavedOperationKind kind;
  final Future<SavedOperationResult> Function() dispatch;
  bool inFlight = false;
}
