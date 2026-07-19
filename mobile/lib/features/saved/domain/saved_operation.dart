import 'dart:convert';
import 'dart:math';

import 'saved_error.dart';
import 'saved_status.dart';
import 'saved_target.dart';

enum SavedMutationKind { save, unsave }

enum SavedSourceSurface {
  unknown('UNKNOWN'),
  card('CARD'),
  detail('DETAIL'),
  savedAll('SAVED_ALL'),
  savedCollection('SAVED_COLLECTION');

  const SavedSourceSurface(this.wireValue);

  final String wireValue;
}

extension SavedMutationKindOperation on SavedMutationKind {
  SavedOperationKind get operationKind => switch (this) {
    SavedMutationKind.save => SavedOperationKind.saveTarget,
    SavedMutationKind.unsave => SavedOperationKind.unsaveTarget,
  };
}

enum SavedOperationKind {
  saveTarget('SAVE_TARGET'),
  unsaveTarget('UNSAVE_TARGET'),
  setTargetCollections('SET_TARGET_COLLECTIONS'),
  createCollection('CREATE_COLLECTION'),
  renameCollection('RENAME_COLLECTION'),
  deleteCollection('DELETE_COLLECTION');

  const SavedOperationKind(this.wireValue);

  final String wireValue;

  static SavedOperationKind fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('operation_kind must be a string.');
    }
    for (final kind in SavedOperationKind.values) {
      if (kind.wireValue == value) {
        return kind;
      }
    }
    throw FormatException('Unsupported operation_kind: $value.');
  }
}

enum SavedOperationStatus {
  pending('PENDING'),
  succeeded('SUCCEEDED'),
  rejected('REJECTED'),
  expired('EXPIRED');

  const SavedOperationStatus(this.wireValue);

  final String wireValue;

  bool get isTerminal => this != SavedOperationStatus.pending;

  static SavedOperationStatus fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('operation_status must be a string.');
    }

    return switch (value) {
      'PENDING' => SavedOperationStatus.pending,
      'SUCCEEDED' => SavedOperationStatus.succeeded,
      'REJECTED' => SavedOperationStatus.rejected,
      'EXPIRED' => SavedOperationStatus.expired,
      _ => throw FormatException('Unsupported operation_status: $value.'),
    };
  }
}

enum SavedOperationOutcome {
  pending('PENDING'),
  applied('APPLIED'),
  noOp('NO_OP'),
  rejected('REJECTED'),
  expired('EXPIRED');

  const SavedOperationOutcome(this.wireValue);

  final String wireValue;

  static SavedOperationOutcome fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('operation_outcome must be a string.');
    }

    return switch (value) {
      'PENDING' => SavedOperationOutcome.pending,
      'APPLIED' => SavedOperationOutcome.applied,
      'NO_OP' => SavedOperationOutcome.noOp,
      'REJECTED' => SavedOperationOutcome.rejected,
      'EXPIRED' => SavedOperationOutcome.expired,
      _ => throw FormatException('Unsupported operation_outcome: $value.'),
    };
  }
}

enum SavedRefreshScope {
  savedItems('SAVED_ITEMS'),
  collections('COLLECTIONS'),
  both('BOTH'),
  none('NONE');

  const SavedRefreshScope(this.wireValue);

  final String wireValue;

  static SavedRefreshScope fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('refresh_scope must be a string.');
    }

    return switch (value) {
      'SAVED_ITEMS' => SavedRefreshScope.savedItems,
      'COLLECTIONS' => SavedRefreshScope.collections,
      'BOTH' => SavedRefreshScope.both,
      'NONE' => SavedRefreshScope.none,
      _ => throw FormatException('Unsupported refresh_scope: $value.'),
    };
  }
}

final class SavedOperationIdentity {
  SavedOperationIdentity({
    required String operationId,
    required String idempotencyKey,
  }) : operationId = validateSavedOperationId(operationId),
       idempotencyKey = _requireIdempotencyKey(idempotencyKey) {
    if (operationId == idempotencyKey) {
      throw ArgumentError(
        'operationId and idempotencyKey must be independently generated.',
      );
    }
  }

  final String operationId;
  final String idempotencyKey;
}

abstract interface class SavedOperationIdentityFactory {
  SavedOperationIdentity create();
}

final class SecureSavedOperationIdentityFactory
    implements SavedOperationIdentityFactory {
  SecureSavedOperationIdentityFactory() : _random = Random.secure();

  final Random _random;

  @override
  SavedOperationIdentity create() {
    final operationBytes = _randomBytes(16);
    operationBytes[6] = (operationBytes[6] & 0x0f) | 0x40;
    operationBytes[8] = (operationBytes[8] & 0x3f) | 0x80;

    final idempotencyBytes = _randomBytes(32);
    return SavedOperationIdentity(
      operationId: _formatUuid(operationBytes),
      idempotencyKey: base64UrlEncode(idempotencyBytes).replaceAll('=', ''),
    );
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }
}

final class SavedMutationOperation {
  const SavedMutationOperation({
    required this.target,
    required this.kind,
    required this.identity,
    required this.createdAt,
    this.sourceSurface = SavedSourceSurface.unknown,
  });

  final SavedTarget target;
  final SavedMutationKind kind;
  final SavedOperationIdentity identity;
  final DateTime createdAt;
  final SavedSourceSurface sourceSurface;
}

final class RelationshipAppliedVersion {
  RelationshipAppliedVersion({required String generation, required int version})
    : generation = _requireUuid(generation, 'generation'),
      version = _requireVersion(version, 'version', positive: true);

  factory RelationshipAppliedVersion.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, requiredKeys: const <String>{'generation', 'version'});
    final generation = json['generation'];
    final version = json['version'];
    if (generation is! String || version is! int) {
      throw const FormatException(
        'relationship applied version fields are malformed.',
      );
    }
    try {
      return RelationshipAppliedVersion(
        generation: generation,
        version: version,
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  final String generation;
  final int version;

  Map<String, Object?> toJson() => <String, Object?>{
    'generation': generation,
    'version': version,
  };
}

final class CollectionAppliedVersion {
  CollectionAppliedVersion({
    required String collectionId,
    required int metadataVersion,
    required int lifecycleVersion,
  }) : collectionId = _requireUuid(collectionId, 'collectionId'),
       metadataVersion = _requireVersion(metadataVersion, 'metadataVersion'),
       lifecycleVersion = _requireVersion(lifecycleVersion, 'lifecycleVersion');

  factory CollectionAppliedVersion.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{
        'collection_id',
        'metadata_version',
        'lifecycle_version',
      },
    );
    final collectionId = json['collection_id'];
    final metadataVersion = json['metadata_version'];
    final lifecycleVersion = json['lifecycle_version'];
    if (collectionId is! String ||
        metadataVersion is! int ||
        lifecycleVersion is! int) {
      throw const FormatException(
        'collection applied version fields are malformed.',
      );
    }
    try {
      return CollectionAppliedVersion(
        collectionId: collectionId,
        metadataVersion: metadataVersion,
        lifecycleVersion: lifecycleVersion,
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  final String collectionId;
  final int metadataVersion;
  final int lifecycleVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'collection_id': collectionId,
    'metadata_version': metadataVersion,
    'lifecycle_version': lifecycleVersion,
  };
}

final class AppliedResourceVersions {
  AppliedResourceVersions({
    this.relationship,
    int? dependentMembershipVersion,
    this.collection,
  }) : dependentMembershipVersion = dependentMembershipVersion == null
           ? null
           : _requireVersion(
               dependentMembershipVersion,
               'dependentMembershipVersion',
             );

  factory AppliedResourceVersions.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{},
      optionalKeys: const <String>{
        'relationship',
        'dependent_membership_version',
        'collection',
      },
    );
    final dependentMembershipVersion = json['dependent_membership_version'];
    if (json.containsKey('dependent_membership_version') &&
        dependentMembershipVersion is! int) {
      throw const FormatException(
        'dependent_membership_version must be an integer when present.',
      );
    }
    try {
      return AppliedResourceVersions(
        relationship: json.containsKey('relationship')
            ? RelationshipAppliedVersion.fromJson(
                _requireObject(json['relationship'], 'relationship'),
              )
            : null,
        dependentMembershipVersion: dependentMembershipVersion as int?,
        collection: json.containsKey('collection')
            ? CollectionAppliedVersion.fromJson(
                _requireObject(json['collection'], 'collection'),
              )
            : null,
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  final RelationshipAppliedVersion? relationship;
  final int? dependentMembershipVersion;
  final CollectionAppliedVersion? collection;

  Map<String, Object?> toJson() => <String, Object?>{
    if (relationship != null) 'relationship': relationship?.toJson(),
    if (dependentMembershipVersion != null)
      'dependent_membership_version': dependentMembershipVersion,
    if (collection != null) 'collection': collection?.toJson(),
  };
}

enum SavedRelationshipState {
  absent('ABSENT'),
  active('ACTIVE'),
  removed('REMOVED');

  const SavedRelationshipState(this.wireValue);

  final String wireValue;
}

sealed class SavedRelationshipSnapshot {
  const SavedRelationshipSnapshot();

  SavedRelationshipState get state;

  String? get generation;

  Map<String, Object?> toJson();

  factory SavedRelationshipSnapshot.fromJson(Map<String, dynamic> json) {
    return switch (json['state']) {
      'ABSENT' => AbsentRelationshipSnapshot.fromJson(json),
      'ACTIVE' || 'REMOVED' => ExistingRelationshipSnapshot.fromJson(json),
      _ => throw FormatException(
        'Unsupported relationship state: ${json['state']}.',
      ),
    };
  }
}

final class AbsentRelationshipSnapshot extends SavedRelationshipSnapshot {
  const AbsentRelationshipSnapshot();

  factory AbsentRelationshipSnapshot.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, requiredKeys: const <String>{'state'});
    if (json['state'] != 'ABSENT') {
      throw const FormatException('Absent relationship state must be ABSENT.');
    }
    return const AbsentRelationshipSnapshot();
  }

  @override
  SavedRelationshipState get state => SavedRelationshipState.absent;

  @override
  String? get generation => null;

  @override
  Map<String, Object?> toJson() => const <String, Object?>{'state': 'ABSENT'};
}

final class ExistingRelationshipSnapshot extends SavedRelationshipSnapshot {
  ExistingRelationshipSnapshot({
    required this.state,
    required String generation,
    required int version,
  }) : generation = _requireUuid(generation, 'generation'),
       version = _requireVersion(version, 'version', positive: true) {
    if (state == SavedRelationshipState.absent) {
      throw ArgumentError.value(
        state,
        'state',
        'Existing relationship must be ACTIVE or REMOVED.',
      );
    }
  }

  factory ExistingRelationshipSnapshot.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{'state', 'generation', 'version'},
    );
    final state = switch (json['state']) {
      'ACTIVE' => SavedRelationshipState.active,
      'REMOVED' => SavedRelationshipState.removed,
      _ => throw const FormatException(
        'Existing relationship state must be ACTIVE or REMOVED.',
      ),
    };
    final generation = json['generation'];
    final version = json['version'];
    if (generation is! String || version is! int) {
      throw const FormatException(
        'Existing relationship fields are malformed.',
      );
    }
    try {
      return ExistingRelationshipSnapshot(
        state: state,
        generation: generation,
        version: version,
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  @override
  final SavedRelationshipState state;
  @override
  final String generation;
  final int version;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.wireValue,
    'generation': generation,
    'version': version,
  };
}

sealed class SavedCurrentResourceSnapshot {
  const SavedCurrentResourceSnapshot();

  String get resourceKind;

  int get snapshotVersion;

  DateTime get snapshotRecordedAt;

  Map<String, Object?> toJson();

  factory SavedCurrentResourceSnapshot.fromJson(Map<String, dynamic> json) {
    return switch (json['resource_kind']) {
      'SAVED_ITEM' => SavedItemCurrentSnapshot.fromJson(json),
      'TARGET_COLLECTIONS' => TargetCollectionsCurrentSnapshot.fromJson(json),
      'COLLECTION' => CollectionCurrentSnapshot.fromJson(json),
      _ => throw FormatException(
        'Unsupported current_resource_snapshot resource_kind: '
        '${json['resource_kind']}.',
      ),
    };
  }
}

final class SavedItemCurrentSnapshot extends SavedCurrentResourceSnapshot {
  SavedItemCurrentSnapshot({
    required int snapshotVersion,
    required DateTime snapshotRecordedAt,
    required this.target,
    required this.savedState,
    required this.relationship,
    required int effectiveCollectionCount,
  }) : snapshotVersion = _requireVersion(snapshotVersion, 'snapshotVersion'),
       snapshotRecordedAt = _requireUtc(
         snapshotRecordedAt,
         'snapshotRecordedAt',
       ),
       effectiveCollectionCount = _requireBoundedInt(
         effectiveCollectionCount,
         'effectiveCollectionCount',
         maximum: 200,
       ) {
    if (savedState == SavedConfirmation.unknown) {
      throw ArgumentError.value(
        savedState,
        'savedState',
        'SAVED_ITEM snapshots cannot contain UNKNOWN.',
      );
    }
  }

  factory SavedItemCurrentSnapshot.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{
        'resource_kind',
        'snapshot_version',
        'snapshot_recorded_at',
        'target',
        'saved_state',
        'relationship',
        'effective_collection_count',
      },
    );
    if (json['resource_kind'] != 'SAVED_ITEM') {
      throw const FormatException('resource_kind must be SAVED_ITEM.');
    }
    final snapshotVersion = json['snapshot_version'];
    final effectiveCollectionCount = json['effective_collection_count'];
    if (snapshotVersion is! int || effectiveCollectionCount is! int) {
      throw const FormatException('SAVED_ITEM version or count is malformed.');
    }
    try {
      return SavedItemCurrentSnapshot(
        snapshotVersion: snapshotVersion,
        snapshotRecordedAt: _parseTimestamp(
          json['snapshot_recorded_at'],
          'snapshot_recorded_at',
        ),
        target: SavedTarget.fromJson(_requireObject(json['target'], 'target')),
        savedState: SavedConfirmation.fromWireValue(json['saved_state']),
        relationship: SavedRelationshipSnapshot.fromJson(
          _requireObject(json['relationship'], 'relationship'),
        ),
        effectiveCollectionCount: effectiveCollectionCount,
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  @override
  String get resourceKind => 'SAVED_ITEM';
  @override
  final int snapshotVersion;
  @override
  final DateTime snapshotRecordedAt;
  final SavedTarget target;
  final SavedConfirmation savedState;
  final SavedRelationshipSnapshot relationship;
  final int effectiveCollectionCount;

  SavedTargetSnapshot toTargetSnapshot() {
    return SavedTargetSnapshot(
      target: target,
      savedState: savedState,
      eligibility: SavedEligibility.unknown,
      effectiveCollectionCount: effectiveCollectionCount,
      relationshipGeneration: relationship.generation,
      resourceVersion: snapshotVersion,
    );
  }

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'resource_kind': resourceKind,
    'snapshot_version': snapshotVersion,
    'snapshot_recorded_at': snapshotRecordedAt.toIso8601String(),
    'target': target.toJson(),
    'saved_state': savedState.wireValue,
    'relationship': relationship.toJson(),
    'effective_collection_count': effectiveCollectionCount,
  };
}

final class TargetCollectionsCurrentSnapshot
    extends SavedCurrentResourceSnapshot {
  TargetCollectionsCurrentSnapshot({
    required int snapshotVersion,
    required DateTime snapshotRecordedAt,
    required this.target,
    required this.relationship,
    required int dependentMembershipVersion,
    required Iterable<String> effectiveCollectionIds,
  }) : snapshotVersion = _requireVersion(snapshotVersion, 'snapshotVersion'),
       snapshotRecordedAt = _requireUtc(
         snapshotRecordedAt,
         'snapshotRecordedAt',
       ),
       dependentMembershipVersion = _requireVersion(
         dependentMembershipVersion,
         'dependentMembershipVersion',
       ),
       effectiveCollectionIds = _requireUniqueUuids(
         effectiveCollectionIds,
         'effectiveCollectionIds',
         maximum: 200,
       );

  factory TargetCollectionsCurrentSnapshot.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{
        'resource_kind',
        'snapshot_version',
        'snapshot_recorded_at',
        'target',
        'relationship',
        'dependent_membership_version',
        'effective_collection_ids',
      },
    );
    if (json['resource_kind'] != 'TARGET_COLLECTIONS') {
      throw const FormatException('resource_kind must be TARGET_COLLECTIONS.');
    }
    final snapshotVersion = json['snapshot_version'];
    final membershipVersion = json['dependent_membership_version'];
    final rawCollectionIds = json['effective_collection_ids'];
    if (snapshotVersion is! int ||
        membershipVersion is! int ||
        rawCollectionIds is! List<dynamic> ||
        rawCollectionIds.any((value) => value is! String)) {
      throw const FormatException(
        'TARGET_COLLECTIONS snapshot fields are malformed.',
      );
    }
    try {
      return TargetCollectionsCurrentSnapshot(
        snapshotVersion: snapshotVersion,
        snapshotRecordedAt: _parseTimestamp(
          json['snapshot_recorded_at'],
          'snapshot_recorded_at',
        ),
        target: SavedTarget.fromJson(_requireObject(json['target'], 'target')),
        relationship: SavedRelationshipSnapshot.fromJson(
          _requireObject(json['relationship'], 'relationship'),
        ),
        dependentMembershipVersion: membershipVersion,
        effectiveCollectionIds: rawCollectionIds.cast<String>(),
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  @override
  String get resourceKind => 'TARGET_COLLECTIONS';
  @override
  final int snapshotVersion;
  @override
  final DateTime snapshotRecordedAt;
  final SavedTarget target;
  final SavedRelationshipSnapshot relationship;
  final int dependentMembershipVersion;
  final List<String> effectiveCollectionIds;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'resource_kind': resourceKind,
    'snapshot_version': snapshotVersion,
    'snapshot_recorded_at': snapshotRecordedAt.toIso8601String(),
    'target': target.toJson(),
    'relationship': relationship.toJson(),
    'dependent_membership_version': dependentMembershipVersion,
    'effective_collection_ids': effectiveCollectionIds,
  };
}

enum SavedCollectionLifecycleState {
  active('ACTIVE'),
  deleted('DELETED');

  const SavedCollectionLifecycleState(this.wireValue);

  final String wireValue;
}

sealed class CollectionCoverPreview {
  const CollectionCoverPreview();

  Map<String, Object?> toJson();

  factory CollectionCoverPreview.fromJson(Map<String, dynamic> json) {
    return switch (json['kind']) {
      'ITEM' => CollectionItemCover.fromJson(json),
      'GENERIC' => GenericCollectionCover.fromJson(json),
      _ => throw FormatException(
        'Unsupported collection cover kind: ${json['kind']}.',
      ),
    };
  }
}

final class CollectionItemCover extends CollectionCoverPreview {
  CollectionItemCover({
    required this.target,
    required String title,
    String? imageUrl,
  }) : title = _requireCodePointLength(
         title,
         'title',
         minimum: 1,
         maximum: 300,
       ),
       imageUrl = imageUrl == null ? null : _requireUri(imageUrl, 'imageUrl');

  factory CollectionItemCover.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{'kind', 'target', 'title'},
      optionalKeys: const <String>{'image_url'},
    );
    if (json['kind'] != 'ITEM') {
      throw const FormatException('Collection item cover kind must be ITEM.');
    }
    final title = json['title'];
    final imageUrl = json['image_url'];
    if (title is! String ||
        (json.containsKey('image_url') && imageUrl is! String)) {
      throw const FormatException(
        'Collection item cover fields are malformed.',
      );
    }
    try {
      return CollectionItemCover(
        target: SavedTarget.fromJson(_requireObject(json['target'], 'target')),
        title: title,
        imageUrl: imageUrl as String?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  final SavedTarget target;
  final String title;
  final String? imageUrl;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'ITEM',
    'target': target.toJson(),
    'title': title,
    if (imageUrl != null) 'image_url': imageUrl,
  };
}

final class GenericCollectionCover extends CollectionCoverPreview {
  const GenericCollectionCover();

  factory GenericCollectionCover.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, requiredKeys: const <String>{'kind'});
    if (json['kind'] != 'GENERIC') {
      throw const FormatException('Generic collection cover kind is invalid.');
    }
    return const GenericCollectionCover();
  }

  @override
  Map<String, Object?> toJson() => const <String, Object?>{'kind': 'GENERIC'};
}

final class SavedCollectionRecord {
  SavedCollectionRecord({
    required String collectionId,
    required String title,
    required int metadataVersion,
    required int lifecycleVersion,
    required int activeItemCount,
    required this.coverPreview,
    required DateTime organizedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : collectionId = _requireUuid(collectionId, 'collectionId'),
       title = _requireCodePointLength(title, 'title', minimum: 1, maximum: 80),
       metadataVersion = _requireVersion(metadataVersion, 'metadataVersion'),
       lifecycleVersion = _requireVersion(lifecycleVersion, 'lifecycleVersion'),
       activeItemCount = _requireBoundedInt(
         activeItemCount,
         'activeItemCount',
         maximum: 5000,
       ),
       organizedAt = _requireUtc(organizedAt, 'organizedAt'),
       createdAt = _requireUtc(createdAt, 'createdAt'),
       updatedAt = _requireUtc(updatedAt, 'updatedAt');

  factory SavedCollectionRecord.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{
        'collection_id',
        'title',
        'lifecycle_state',
        'metadata_version',
        'lifecycle_version',
        'active_item_count',
        'cover_preview',
        'organized_at',
        'created_at',
        'updated_at',
      },
    );
    if (json['lifecycle_state'] != 'ACTIVE') {
      throw const FormatException('Saved collection must be ACTIVE.');
    }
    final collectionId = json['collection_id'];
    final title = json['title'];
    final metadataVersion = json['metadata_version'];
    final lifecycleVersion = json['lifecycle_version'];
    final activeItemCount = json['active_item_count'];
    if (collectionId is! String ||
        title is! String ||
        metadataVersion is! int ||
        lifecycleVersion is! int ||
        activeItemCount is! int) {
      throw const FormatException('Saved collection fields are malformed.');
    }
    try {
      return SavedCollectionRecord(
        collectionId: collectionId,
        title: title,
        metadataVersion: metadataVersion,
        lifecycleVersion: lifecycleVersion,
        activeItemCount: activeItemCount,
        coverPreview: CollectionCoverPreview.fromJson(
          _requireObject(json['cover_preview'], 'cover_preview'),
        ),
        organizedAt: _parseTimestamp(json['organized_at'], 'organized_at'),
        createdAt: _parseTimestamp(json['created_at'], 'created_at'),
        updatedAt: _parseTimestamp(json['updated_at'], 'updated_at'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  final String collectionId;
  final String title;
  final int metadataVersion;
  final int lifecycleVersion;
  final int activeItemCount;
  final CollectionCoverPreview coverPreview;
  final DateTime organizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'collection_id': collectionId,
    'title': title,
    'lifecycle_state': 'ACTIVE',
    'metadata_version': metadataVersion,
    'lifecycle_version': lifecycleVersion,
    'active_item_count': activeItemCount,
    'cover_preview': coverPreview.toJson(),
    'organized_at': organizedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

final class CollectionCurrentSnapshot extends SavedCurrentResourceSnapshot {
  CollectionCurrentSnapshot({
    required int snapshotVersion,
    required DateTime snapshotRecordedAt,
    required String collectionId,
    required this.lifecycleState,
    required int metadataVersion,
    required int lifecycleVersion,
    this.collection,
  }) : snapshotVersion = _requireVersion(snapshotVersion, 'snapshotVersion'),
       snapshotRecordedAt = _requireUtc(
         snapshotRecordedAt,
         'snapshotRecordedAt',
       ),
       collectionId = _requireUuid(collectionId, 'collectionId'),
       metadataVersion = _requireVersion(metadataVersion, 'metadataVersion'),
       lifecycleVersion = _requireVersion(
         lifecycleVersion,
         'lifecycleVersion',
       ) {
    if ((lifecycleState == SavedCollectionLifecycleState.active) !=
        (collection != null)) {
      throw ArgumentError(
        'ACTIVE collection snapshots require collection data; '
        'DELETED snapshots forbid it.',
      );
    }
  }

  factory CollectionCurrentSnapshot.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{
        'resource_kind',
        'snapshot_version',
        'snapshot_recorded_at',
        'collection_id',
        'lifecycle_state',
        'metadata_version',
        'lifecycle_version',
      },
      optionalKeys: const <String>{'collection'},
    );
    if (json['resource_kind'] != 'COLLECTION') {
      throw const FormatException('resource_kind must be COLLECTION.');
    }
    final lifecycleState = switch (json['lifecycle_state']) {
      'ACTIVE' => SavedCollectionLifecycleState.active,
      'DELETED' => SavedCollectionLifecycleState.deleted,
      _ => throw const FormatException(
        'Collection lifecycle_state must be ACTIVE or DELETED.',
      ),
    };
    final snapshotVersion = json['snapshot_version'];
    final collectionId = json['collection_id'];
    final metadataVersion = json['metadata_version'];
    final lifecycleVersion = json['lifecycle_version'];
    if (snapshotVersion is! int ||
        collectionId is! String ||
        metadataVersion is! int ||
        lifecycleVersion is! int) {
      throw const FormatException('Collection snapshot fields are malformed.');
    }
    try {
      return CollectionCurrentSnapshot(
        snapshotVersion: snapshotVersion,
        snapshotRecordedAt: _parseTimestamp(
          json['snapshot_recorded_at'],
          'snapshot_recorded_at',
        ),
        collectionId: collectionId,
        lifecycleState: lifecycleState,
        metadataVersion: metadataVersion,
        lifecycleVersion: lifecycleVersion,
        collection: json.containsKey('collection')
            ? SavedCollectionRecord.fromJson(
                _requireObject(json['collection'], 'collection'),
              )
            : null,
      );
    } on ArgumentError catch (error) {
      throw FormatException(_argumentErrorMessage(error));
    }
  }

  @override
  String get resourceKind => 'COLLECTION';
  @override
  final int snapshotVersion;
  @override
  final DateTime snapshotRecordedAt;
  final String collectionId;
  final SavedCollectionLifecycleState lifecycleState;
  final int metadataVersion;
  final int lifecycleVersion;
  final SavedCollectionRecord? collection;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'resource_kind': resourceKind,
    'snapshot_version': snapshotVersion,
    'snapshot_recorded_at': snapshotRecordedAt.toIso8601String(),
    'collection_id': collectionId,
    'lifecycle_state': lifecycleState.wireValue,
    'metadata_version': metadataVersion,
    'lifecycle_version': lifecycleVersion,
    if (collection != null) 'collection': collection?.toJson(),
  };
}

final class SavedOperationResult {
  SavedOperationResult({
    required String operationId,
    required this.operationKind,
    required this.status,
    required this.outcome,
    required DateTime commitDeadline,
    required this.refreshScope,
    required this.appliedResourceVersions,
    required DateTime resultRecordedAt,
    this.operationError,
    this.currentResourceSnapshot,
  }) : operationId = validateSavedOperationId(operationId),
       commitDeadline = _requireUtc(commitDeadline, 'commitDeadline'),
       resultRecordedAt = _requireUtc(resultRecordedAt, 'resultRecordedAt') {
    _validateOperationCombination(
      status: status,
      outcome: outcome,
      operationError: operationError,
    );
  }

  factory SavedOperationResult.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{
        'operation_id',
        'operation_kind',
        'operation_status',
        'operation_outcome',
        'commit_deadline',
        'refresh_scope',
        'applied_resource_versions',
        'result_recorded_at',
      },
      optionalKeys: const <String>{
        'operation_error',
        'current_resource_snapshot',
      },
    );

    final operationId = json['operation_id'];
    if (operationId is! String) {
      throw const FormatException('operation_id must be a string.');
    }
    if (json.containsKey('operation_error') &&
        json['operation_error'] == null) {
      throw const FormatException('operation_error cannot be null.');
    }
    if (json.containsKey('current_resource_snapshot') &&
        json['current_resource_snapshot'] == null) {
      throw const FormatException('current_resource_snapshot cannot be null.');
    }

    try {
      return SavedOperationResult(
        operationId: operationId,
        operationKind: SavedOperationKind.fromWireValue(json['operation_kind']),
        status: SavedOperationStatus.fromWireValue(json['operation_status']),
        outcome: SavedOperationOutcome.fromWireValue(json['operation_outcome']),
        commitDeadline: _parseTimestamp(
          json['commit_deadline'],
          'commit_deadline',
        ),
        refreshScope: SavedRefreshScope.fromWireValue(json['refresh_scope']),
        appliedResourceVersions: AppliedResourceVersions.fromJson(
          _requireObject(
            json['applied_resource_versions'],
            'applied_resource_versions',
          ),
        ),
        resultRecordedAt: _parseTimestamp(
          json['result_recorded_at'],
          'result_recorded_at',
        ),
        operationError: json.containsKey('operation_error')
            ? SavedOperationError.fromJson(
                _requireObject(json['operation_error'], 'operation_error'),
              )
            : null,
        currentResourceSnapshot: json.containsKey('current_resource_snapshot')
            ? SavedCurrentResourceSnapshot.fromJson(
                _requireObject(
                  json['current_resource_snapshot'],
                  'current_resource_snapshot',
                ),
              )
            : null,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        error.message?.toString() ?? 'Invalid Saved operation result.',
      );
    }
  }

  final String operationId;
  final SavedOperationKind operationKind;
  final SavedOperationStatus status;
  final SavedOperationOutcome outcome;
  final DateTime commitDeadline;
  final SavedRefreshScope refreshScope;
  final AppliedResourceVersions appliedResourceVersions;
  final DateTime resultRecordedAt;
  final SavedOperationError? operationError;
  final SavedCurrentResourceSnapshot? currentResourceSnapshot;

  SavedItemCurrentSnapshot? get savedItemSnapshot {
    final snapshot = currentResourceSnapshot;
    return snapshot is SavedItemCurrentSnapshot ? snapshot : null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'operation_id': operationId,
    'operation_kind': operationKind.wireValue,
    'operation_status': status.wireValue,
    'operation_outcome': outcome.wireValue,
    'commit_deadline': commitDeadline.toIso8601String(),
    'refresh_scope': refreshScope.wireValue,
    'applied_resource_versions': appliedResourceVersions.toJson(),
    'result_recorded_at': resultRecordedAt.toIso8601String(),
    if (operationError != null) 'operation_error': operationError?.toJson(),
    if (currentResourceSnapshot != null)
      'current_resource_snapshot': currentResourceSnapshot?.toJson(),
  };
}

final RegExp _uuidV4Pattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-'
  r'[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

final RegExp _rfc3339Pattern = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
  r'(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
);

const int _maximumInt64 = 9223372036854775807;

String validateSavedOperationId(String value) {
  if (!_uuidV4Pattern.hasMatch(value)) {
    throw ArgumentError.value(value, 'operationId', 'Must be a UUIDv4.');
  }
  return value;
}

String _formatUuid(List<int> bytes) {
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

String _requireIdempotencyKey(String value) {
  if (value.length < 22 || value.length > 128) {
    throw ArgumentError.value(
      value,
      'idempotencyKey',
      'Length must be between 22 and 128 characters.',
    );
  }
  if (!RegExp(r'^[A-Za-z0-9_-]{22,128}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'idempotencyKey',
      'Must be unpadded base64url.',
    );
  }

  try {
    final padded = value.padRight((value.length + 3) ~/ 4 * 4, '=');
    if (base64Url.decode(padded).length < 16) {
      throw ArgumentError.value(
        value,
        'idempotencyKey',
        'Must contain at least 128 bits.',
      );
    }
  } on FormatException {
    throw ArgumentError.value(
      value,
      'idempotencyKey',
      'Must be valid unpadded base64url.',
    );
  }
  return value;
}

String _requireUuid(String value, String name) {
  if (!_uuidPattern.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Must be a UUID.');
  }
  return value;
}

int _requireVersion(int value, String name, {bool positive = false}) {
  final minimum = positive ? 1 : 0;
  if (value < minimum || value > _maximumInt64) {
    throw ArgumentError.value(
      value,
      name,
      'Must be between $minimum and $_maximumInt64.',
    );
  }
  return value;
}

int _requireBoundedInt(int value, String name, {required int maximum}) {
  if (value < 0 || value > maximum) {
    throw ArgumentError.value(value, name, 'Must be between 0 and $maximum.');
  }
  return value;
}

List<String> _requireUniqueUuids(
  Iterable<String> values,
  String name, {
  required int maximum,
}) {
  final result = List<String>.unmodifiable(values);
  if (result.length > maximum) {
    throw ArgumentError.value(
      result.length,
      name,
      'Must have at most $maximum.',
    );
  }
  final unique = <String>{};
  for (final value in result) {
    _requireUuid(value, name);
    if (!unique.add(value)) {
      throw ArgumentError.value(value, name, 'Must not contain duplicates.');
    }
  }
  return result;
}

String _requireCodePointLength(
  String value,
  String name, {
  required int minimum,
  required int maximum,
}) {
  final length = value.runes.length;
  if (length < minimum || length > maximum) {
    throw ArgumentError.value(
      value,
      name,
      'Must contain between $minimum and $maximum Unicode code points.',
    );
  }
  return value;
}

String _requireUri(String value, String name) {
  if (value.runes.length > 2048) {
    throw ArgumentError.value(value, name, 'Must not exceed 2048 characters.');
  }
  final parsed = Uri.tryParse(value);
  if (parsed == null || !parsed.hasScheme) {
    throw ArgumentError.value(value, name, 'Must be an absolute URI.');
  }
  return value;
}

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'Must include a UTC offset.');
  }
  return value;
}

DateTime _parseTimestamp(Object? value, String fieldName) {
  if (value is! String || !_rfc3339Pattern.hasMatch(value)) {
    throw FormatException('$fieldName must be an RFC 3339 date-time string.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('$fieldName must include a UTC offset.');
  }
  return parsed;
}

Map<String, dynamic> _requireObject(Object? value, String fieldName) {
  if (value is! Map<dynamic, dynamic> ||
      value.keys.any((key) => key is! String)) {
    throw FormatException('$fieldName must be an object with string keys.');
  }
  return Map<String, dynamic>.from(value);
}

void _requireKeys(
  Map<String, dynamic> json, {
  required Set<String> requiredKeys,
  Set<String> optionalKeys = const <String>{},
}) {
  final actualKeys = json.keys.toSet();
  final allowedKeys = <String>{...requiredKeys, ...optionalKeys};
  if (!actualKeys.containsAll(requiredKeys) ||
      !allowedKeys.containsAll(actualKeys)) {
    throw FormatException(
      'Unexpected JSON keys. Required: ${requiredKeys.toList()..sort()}; '
      'optional: ${optionalKeys.toList()..sort()}.',
    );
  }
}

void _validateOperationCombination({
  required SavedOperationStatus status,
  required SavedOperationOutcome outcome,
  required SavedOperationError? operationError,
}) {
  final valid = switch (status) {
    SavedOperationStatus.pending =>
      outcome == SavedOperationOutcome.pending && operationError == null,
    SavedOperationStatus.succeeded =>
      (outcome == SavedOperationOutcome.applied ||
              outcome == SavedOperationOutcome.noOp) &&
          operationError == null,
    SavedOperationStatus.rejected =>
      outcome == SavedOperationOutcome.rejected && operationError != null,
    SavedOperationStatus.expired =>
      outcome == SavedOperationOutcome.expired && operationError == null,
  };
  if (!valid) {
    throw ArgumentError(
      'Invalid operation_status, operation_outcome, and operation_error '
      'combination.',
    );
  }
}

String _argumentErrorMessage(ArgumentError error) {
  return error.message?.toString() ?? 'Invalid Saved wire value.';
}
