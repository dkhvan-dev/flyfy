import 'saved_target.dart';

enum SavedConfirmation {
  saved('SAVED'),
  confirmedUnsaved('CONFIRMED_UNSAVED'),
  unknown('UNKNOWN');

  const SavedConfirmation(this.wireValue);

  final String wireValue;

  static SavedConfirmation fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('saved_state must be a string.');
    }

    return switch (value) {
      'SAVED' => SavedConfirmation.saved,
      'CONFIRMED_UNSAVED' => SavedConfirmation.confirmedUnsaved,
      'UNKNOWN' => SavedConfirmation.unknown,
      _ => throw FormatException('Unsupported saved_state: $value.'),
    };
  }
}

enum SavedEligibility {
  eligible('ELIGIBLE'),
  reductionOnly('REDUCTION_ONLY'),
  ineligible('INELIGIBLE'),
  unknown('UNKNOWN');

  const SavedEligibility(this.wireValue);

  final String wireValue;

  static SavedEligibility fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('eligibility_hint must be a string.');
    }

    return switch (value) {
      'ELIGIBLE' => SavedEligibility.eligible,
      'REDUCTION_ONLY' => SavedEligibility.reductionOnly,
      'INELIGIBLE' => SavedEligibility.ineligible,
      'UNKNOWN' => SavedEligibility.unknown,
      _ => throw FormatException('Unsupported eligibility_hint: $value.'),
    };
  }
}

final class SavedTargetSnapshot {
  SavedTargetSnapshot({
    required this.target,
    required this.savedState,
    required this.eligibility,
    required int effectiveCollectionCount,
    String? relationshipGeneration,
    required int resourceVersion,
  }) : effectiveCollectionCount = _requireBoundedInt(
         effectiveCollectionCount,
         'effectiveCollectionCount',
         maximum: 200,
       ),
       relationshipGeneration = relationshipGeneration == null
           ? null
           : _requireUuid(relationshipGeneration, 'relationshipGeneration'),
       resourceVersion = _requireVersion(resourceVersion, 'resourceVersion');

  factory SavedTargetSnapshot.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{
        'target',
        'saved_state',
        'effective_collection_count',
        'eligibility_hint',
        'resource_version',
      },
      optionalKeys: const <String>{'relationship_generation'},
    );

    final effectiveCollectionCount = json['effective_collection_count'];
    if (effectiveCollectionCount is! int) {
      throw const FormatException(
        'effective_collection_count must be an integer.',
      );
    }
    final resourceVersion = json['resource_version'];
    if (resourceVersion is! int) {
      throw const FormatException('resource_version must be an integer.');
    }
    final relationshipGeneration = json['relationship_generation'];
    if (json.containsKey('relationship_generation') &&
        relationshipGeneration is! String) {
      throw const FormatException(
        'relationship_generation must be a UUID string when present.',
      );
    }

    try {
      return SavedTargetSnapshot(
        target: SavedTarget.fromJson(_requireObject(json['target'], 'target')),
        savedState: SavedConfirmation.fromWireValue(json['saved_state']),
        eligibility: SavedEligibility.fromWireValue(json['eligibility_hint']),
        effectiveCollectionCount: effectiveCollectionCount,
        relationshipGeneration: relationshipGeneration as String?,
        resourceVersion: resourceVersion,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid status.');
    }
  }

  final SavedTarget target;
  final SavedConfirmation savedState;
  final SavedEligibility eligibility;
  final int effectiveCollectionCount;
  final String? relationshipGeneration;
  final int resourceVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'target': target.toJson(),
      'saved_state': savedState.wireValue,
      'effective_collection_count': effectiveCollectionCount,
      'eligibility_hint': eligibility.wireValue,
      if (relationshipGeneration != null)
        'relationship_generation': relationshipGeneration,
      'resource_version': resourceVersion,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SavedTargetSnapshot &&
            target == other.target &&
            savedState == other.savedState &&
            eligibility == other.eligibility &&
            effectiveCollectionCount == other.effectiveCollectionCount &&
            relationshipGeneration == other.relationshipGeneration &&
            resourceVersion == other.resourceVersion;
  }

  @override
  int get hashCode => Object.hash(
    target,
    savedState,
    eligibility,
    effectiveCollectionCount,
    relationshipGeneration,
    resourceVersion,
  );
}

final class SavedStatusBatch {
  SavedStatusBatch(Iterable<SavedTargetSnapshot> statuses)
    : statuses = List<SavedTargetSnapshot>.unmodifiable(statuses) {
    if (this.statuses.length > 100) {
      throw ArgumentError.value(
        this.statuses.length,
        'statuses',
        'Must contain at most 100 statuses.',
      );
    }

    final targets = <SavedTarget>{};
    for (final status in this.statuses) {
      if (!targets.add(status.target)) {
        throw ArgumentError.value(
          status.target,
          'statuses',
          'Duplicate Saved target.',
        );
      }
    }
  }

  factory SavedStatusBatch.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, requiredKeys: const <String>{'statuses'});
    final rawStatuses = json['statuses'];
    if (rawStatuses is! List<dynamic>) {
      throw const FormatException('statuses must be an array.');
    }

    final parsed = <SavedTargetSnapshot>[];
    for (final rawStatus in rawStatuses) {
      parsed.add(
        SavedTargetSnapshot.fromJson(_requireObject(rawStatus, 'status')),
      );
    }

    try {
      return SavedStatusBatch(parsed);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid statuses.');
    }
  }

  final List<SavedTargetSnapshot> statuses;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'statuses': statuses
          .map((status) => status.toJson())
          .toList(growable: false),
    };
  }
}

const int _maximumInt64 = 9223372036854775807;

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

int _requireBoundedInt(int value, String name, {required int maximum}) {
  if (value < 0 || value > maximum) {
    throw ArgumentError.value(value, name, 'Must be between 0 and $maximum.');
  }
  return value;
}

int _requireVersion(int value, String name) {
  return _requireBoundedInt(value, name, maximum: _maximumInt64);
}

String _requireUuid(String value, String name) {
  if (!_uuidPattern.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Must be a UUID.');
  }
  return value;
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
