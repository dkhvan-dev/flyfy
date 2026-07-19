import 'dart:async';

import 'package:dio/dio.dart';
import 'package:inflap/features/saved/data/saved_feature_repository.dart';
import 'package:inflap/features/saved/data/saved_repository.dart';
import 'package:inflap/features/saved/domain/saved_browse_models.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_state_registry.dart';

class SavedListCall {
  const SavedListCall({
    required this.entityType,
    required this.collectionId,
    required this.cursor,
    required this.cancelToken,
  });

  final SavedEntityType? entityType;
  final String? collectionId;
  final String? cursor;
  final CancelToken? cancelToken;
}

final class SavedSearchCall extends SavedListCall {
  const SavedSearchCall({
    required this.search,
    required super.entityType,
    required super.collectionId,
    required super.cursor,
    required super.cancelToken,
  });

  final String search;
}

final class SavedMutationCall {
  const SavedMutationCall({required this.target, required this.sourceSurface});

  final SavedTarget target;
  final SavedSourceSurface sourceSurface;
}

final class FakeSavedFeatureRepository implements SavedFeatureRepository {
  FakeSavedFeatureRepository({
    SavedCapabilities? capabilities,
    List<SavedListItem> initialItems = const [],
    List<SavedCollectionRecord> initialCollections = const [],
  }) : capabilities = capabilities ?? enabledCapabilities(),
       listPage = SavedPage<SavedListItem>(
         items: initialItems,
         nextCursor: null,
         hasMore: false,
         validateDateOrder: true,
       ),
       collectionsList = SavedCollectionsList(collections: initialCollections);

  @override
  final SavedStateRegistry registry = SavedStateRegistry();
  SavedCapabilities capabilities;
  SavedPage<SavedListItem> listPage;
  SavedPage<SavedSearchItem> searchPage = SavedPage<SavedSearchItem>(
    items: const [],
    nextCursor: null,
    hasMore: false,
  );
  SavedCollectionsList collectionsList;
  SavedTargetCollectionsSnapshot? targetCollectionsSnapshot;
  Future<SavedPage<SavedListItem>> Function(SavedListCall call)? listHandler;
  Future<SavedPage<SavedSearchItem>> Function(SavedSearchCall call)?
  searchHandler;
  Future<SavedCapabilities> Function()? capabilitiesHandler;
  Future<SavedCollectionsList> Function()? collectionsHandler;
  Future<SavedCommandExecution> Function()? commandHandler;
  Future<List<SavedTargetSnapshot>> Function(List<SavedTarget> targets)?
  bootstrapHandler;
  Future<SavedMutationExecution> Function(SavedMutationCall call)? saveHandler;
  Future<SavedMutationExecution> Function(SavedMutationCall call)?
  unsaveHandler;
  Future<SavedMutationExecution> Function(SavedTarget target)? resolveHandler;
  Future<SavedMutationExecution> Function(SavedTarget target)? globalHandler;
  final List<SavedListCall> listCalls = <SavedListCall>[];
  final List<SavedSearchCall> searchCalls = <SavedSearchCall>[];
  final List<String> createdTitles = <String>[];
  final List<String> renamedTitles = <String>[];
  final List<String> deletedCollectionIds = <String>[];
  final List<Set<String>> desiredAssignments = <Set<String>>[];
  final List<SavedSourceSurface> assignmentSources = <SavedSourceSurface>[];
  final List<SavedTarget> targetCollectionsCalls = <SavedTarget>[];
  final List<List<SavedTarget>> bootstrapCalls = <List<SavedTarget>>[];
  final List<SavedMutationCall> saveCalls = <SavedMutationCall>[];
  final List<SavedMutationCall> unsaveCalls = <SavedMutationCall>[];
  final List<SavedTarget> resolveCalls = <SavedTarget>[];
  final Set<SavedCommandKey> activeCommands = <SavedCommandKey>{};
  int clearCount = 0;
  int _resourceVersion = 100;

  @override
  Future<SavedCapabilities> getCapabilities({CancelToken? cancelToken}) async {
    return capabilitiesHandler?.call() ?? capabilities;
  }

  @override
  Future<SavedPage<SavedListItem>> listItems({
    SavedEntityType? entityType,
    String? collectionId,
    String? cursor,
    CancelToken? cancelToken,
  }) {
    final call = SavedListCall(
      entityType: entityType,
      collectionId: collectionId,
      cursor: cursor,
      cancelToken: cancelToken,
    );
    listCalls.add(call);
    return listHandler?.call(call) ?? Future.value(listPage);
  }

  @override
  Future<SavedPage<SavedSearchItem>> searchItems({
    required String search,
    SavedEntityType? entityType,
    String? collectionId,
    String? cursor,
    CancelToken? cancelToken,
  }) {
    final call = SavedSearchCall(
      search: search,
      entityType: entityType,
      collectionId: collectionId,
      cursor: cursor,
      cancelToken: cancelToken,
    );
    searchCalls.add(call);
    return searchHandler?.call(call) ?? Future.value(searchPage);
  }

  @override
  Future<SavedCollectionsList> listCollections({CancelToken? cancelToken}) =>
      collectionsHandler?.call() ?? Future.value(collectionsList);

  @override
  Future<SavedCollectionDetail> getCollection(
    String collectionId, {
    CancelToken? cancelToken,
  }) async {
    return SavedCollectionDetail(
      collection: collectionsList.collections.singleWhere(
        (item) => item.collectionId == collectionId,
      ),
    );
  }

  @override
  Future<SavedTargetCollectionsSnapshot> getTargetCollections(
    SavedTarget target, {
    CancelToken? cancelToken,
  }) async {
    targetCollectionsCalls.add(target);
    final snapshot = targetCollectionsSnapshot;
    if (snapshot == null) {
      throw StateError('No target collection fixture configured.');
    }
    return snapshot;
  }

  @override
  Future<List<SavedTargetSnapshot>> bootstrapTargetStatuses(
    Iterable<SavedTarget> targets,
  ) async {
    final requested = List<SavedTarget>.unmodifiable(targets);
    bootstrapCalls.add(requested);
    final statuses =
        await bootstrapHandler?.call(requested) ??
        requested
            .map(
              (target) => SavedTargetSnapshot(
                target: target,
                savedState: SavedConfirmation.confirmedUnsaved,
                eligibility: SavedEligibility.eligible,
                effectiveCollectionCount: 0,
                resourceVersion: ++_resourceVersion,
              ),
            )
            .toList(growable: false);
    registry.hydrateBatch(statuses);
    return List<SavedTargetSnapshot>.unmodifiable(statuses);
  }

  @override
  Future<SavedMutationExecution> save(
    SavedTarget target, {
    required SavedSourceSurface sourceSurface,
  }) async {
    final call = SavedMutationCall(
      target: target,
      sourceSurface: sourceSurface,
    );
    saveCalls.add(call);
    final handler = saveHandler;
    if (handler != null) return handler(call);
    registry.applySnapshot(
      SavedTargetSnapshot(
        target: target,
        savedState: SavedConfirmation.saved,
        eligibility: SavedEligibility.eligible,
        effectiveCollectionCount: 0,
        relationshipGeneration: relationshipGeneration,
        resourceVersion: ++_resourceVersion,
      ),
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
    required SavedSourceSurface sourceSurface,
  }) async {
    final call = SavedMutationCall(
      target: target,
      sourceSurface: sourceSurface,
    );
    unsaveCalls.add(call);
    final handler = unsaveHandler;
    if (handler != null) return handler(call);
    final legacyHandler = globalHandler;
    if (legacyHandler != null) return legacyHandler(target);
    registry.applySnapshot(
      SavedTargetSnapshot(
        target: target,
        savedState: SavedConfirmation.confirmedUnsaved,
        eligibility: SavedEligibility.eligible,
        effectiveCollectionCount: 0,
        resourceVersion: ++_resourceVersion,
      ),
    );
    return successfulMutationExecution(
      target,
      kind: SavedMutationKind.unsave,
      sourceSurface: sourceSurface,
    );
  }

  @override
  Future<SavedMutationExecution> resolveLiveMutation(SavedTarget target) {
    resolveCalls.add(target);
    return resolveHandler?.call(target) ??
        globalHandler?.call(target) ??
        Future.value(successfulGlobalExecution(target));
  }

  @override
  Future<SavedCommandExecution> replaceTargetCollections({
    required SavedTargetCollectionsSnapshot current,
    required Iterable<String> desiredCollectionIds,
    String? newCollectionTitle,
    required SavedSourceSurface sourceSurface,
  }) {
    desiredAssignments.add(desiredCollectionIds.toSet());
    assignmentSources.add(sourceSurface);
    if (newCollectionTitle != null) createdTitles.add(newCollectionTitle);
    return _command(
      SavedCommandKey.assignment(current.target),
      SavedOperationKind.setTargetCollections,
    );
  }

  @override
  Future<SavedCommandExecution> createCollection({
    required String title,
    required SavedSourceSurface sourceSurface,
  }) {
    createdTitles.add(title);
    return _command(
      SavedCommandKey.createCollection(),
      SavedOperationKind.createCollection,
    );
  }

  @override
  Future<SavedCommandExecution> renameCollection({
    required SavedCollectionRecord collection,
    required String title,
    required SavedSourceSurface sourceSurface,
  }) {
    renamedTitles.add(title);
    return _command(
      SavedCommandKey.collection(collection.collectionId),
      SavedOperationKind.renameCollection,
    );
  }

  @override
  Future<SavedCommandExecution> deleteCollection({
    required SavedCollectionRecord collection,
    required SavedSourceSurface sourceSurface,
  }) {
    deletedCollectionIds.add(collection.collectionId);
    return _command(
      SavedCommandKey.collection(collection.collectionId),
      SavedOperationKind.deleteCollection,
    );
  }

  @override
  Future<SavedCommandExecution> retryCommand(SavedCommandKey key) {
    return _command(key, SavedOperationKind.setTargetCollections);
  }

  @override
  bool isCommandActive(SavedCommandKey key) => activeCommands.contains(key);

  @override
  void clearForLogout() {
    clearCount++;
    activeCommands.clear();
    registry.clearForLogout();
  }

  Future<SavedCommandExecution> _command(
    SavedCommandKey key,
    SavedOperationKind kind,
  ) {
    if (commandHandler != null) return commandHandler!();
    return Future.value(
      SavedCommandExecution(
        key: key,
        state: SavedCommandExecutionState.succeeded,
        serverResult: operationResult(kind: kind),
      ),
    );
  }
}

SavedCapabilities enabledCapabilities({
  Set<SavedEntityType>? supportedTypes,
  bool search = true,
  bool collections = true,
}) {
  return SavedCapabilities(
    capabilityRevision: 'test-revision',
    productFlags: SavedProductFlags(
      savedItemsEnabled: true,
      searchEnabled: search,
      collectionsEnabled: collections,
    ),
    hasConfirmedSavedData: true,
    supportedEntityTypes:
        supportedTypes ??
        const <SavedEntityType>{
          SavedEntityType.attraction,
          SavedEntityType.activity,
          SavedEntityType.user,
          SavedEntityType.post,
        },
    effectiveLocale: SavedDisplayLocale.en,
  );
}

SavedListItem savedListItem({
  String id = 'activity-1',
  String title = 'Mountain walk',
  DateTime? savedAt,
  int collectionCount = 1,
  SavedEntityType type = SavedEntityType.activity,
  bool available = true,
  String? canonicalDetailRoute,
  String? imageUrl,
}) {
  return SavedListItem(
    target: SavedTarget(entityType: type, entityId: id),
    relationship: SavedActiveRelationship(
      generation: relationshipGeneration,
      version: 1,
      savedAt: savedAt ?? DateTime.utc(2026, 7, 16, 10),
    ),
    effectiveCollectionCount: collectionCount,
    projection: available
        ? AvailableSavedCardProjection(
            projectionVersion: 1,
            displayLocale: SavedDisplayLocale.en,
            title: title,
            canonicalDetailRoute: canonicalDetailRoute ?? '/activities/$id',
            subtitle: 'Almaty',
            imageUrl: imageUrl == null ? null : Uri.parse(imageUrl),
          )
        : UnavailableSavedCardProjection(projectionVersion: 1),
  );
}

SavedCollectionRecord savedCollection({
  String id = collectionA,
  String title = 'Weekend',
  int itemCount = 1,
}) {
  return SavedCollectionRecord(
    collectionId: id,
    title: title,
    metadataVersion: 1,
    lifecycleVersion: 1,
    activeItemCount: itemCount,
    coverPreview: const GenericCollectionCover(),
    organizedAt: DateTime.utc(2026, 7, 16, 10),
    createdAt: DateTime.utc(2026, 7, 1, 10),
    updatedAt: DateTime.utc(2026, 7, 16, 10),
  );
}

SavedTargetCollectionsSnapshot targetCollections(
  SavedTarget target, {
  List<String> effectiveIds = const [collectionA],
}) {
  return SavedTargetCollectionsSnapshot(
    snapshotVersion: 2,
    target: target,
    relationship: ExistingRelationshipSnapshot(
      state: SavedRelationshipState.active,
      generation: relationshipGeneration,
      version: 1,
    ),
    dependentMembershipVersion: 1,
    effectiveCollectionIds: effectiveIds,
    collectionOptions: [
      SavedCollectionOption(
        collectionId: collectionA,
        title: 'Weekend',
        metadataVersion: 1,
        lifecycleVersion: 1,
      ),
      SavedCollectionOption(
        collectionId: collectionB,
        title: 'Summer',
        metadataVersion: 1,
        lifecycleVersion: 1,
      ),
    ],
  );
}

SavedCommandExecution successfulCommand(
  SavedCommandKey key, {
  SavedOperationKind kind = SavedOperationKind.setTargetCollections,
}) {
  return SavedCommandExecution(
    key: key,
    state: SavedCommandExecutionState.succeeded,
    serverResult: operationResult(kind: kind),
  );
}

SavedOperationResult operationResult({
  required SavedOperationKind kind,
  SavedOperationStatus status = SavedOperationStatus.succeeded,
  SavedOperationOutcome outcome = SavedOperationOutcome.applied,
}) {
  return SavedOperationResult(
    operationId: operationId,
    operationKind: kind,
    status: status,
    outcome: outcome,
    commitDeadline: DateTime.utc(2026, 7, 16, 10, 0, 15),
    refreshScope: SavedRefreshScope.both,
    appliedResourceVersions: AppliedResourceVersions(),
    resultRecordedAt: DateTime.utc(2026, 7, 16, 10, 0, 1),
  );
}

SavedMutationExecution successfulGlobalExecution(SavedTarget target) {
  return successfulMutationExecution(
    target,
    kind: SavedMutationKind.unsave,
    sourceSurface: SavedSourceSurface.savedAll,
  );
}

SavedMutationExecution successfulMutationExecution(
  SavedTarget target, {
  required SavedMutationKind kind,
  required SavedSourceSurface sourceSurface,
  SavedMutationExecutionState state = SavedMutationExecutionState.succeeded,
}) {
  final identity = SavedOperationIdentity(
    operationId: operationId,
    idempotencyKey: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  );
  return SavedMutationExecution(
    operation: SavedMutationOperation(
      target: target,
      kind: kind,
      identity: identity,
      createdAt: DateTime.utc(2026, 7, 16, 10),
      sourceSurface: sourceSurface,
    ),
    state: state,
    serverResult: operationResult(
      kind: kind.operationKind,
      status: state == SavedMutationExecutionState.pending
          ? SavedOperationStatus.pending
          : SavedOperationStatus.succeeded,
      outcome: state == SavedMutationExecutionState.pending
          ? SavedOperationOutcome.pending
          : SavedOperationOutcome.applied,
    ),
  );
}

const operationId = '11111111-2222-4333-8444-555555555555';
const relationshipGeneration = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const collectionA = '11111111-2222-3333-4444-555555555555';
const collectionB = '66666666-7777-8888-9999-aaaaaaaaaaaa';
