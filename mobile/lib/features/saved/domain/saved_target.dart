import 'dart:convert';

enum SavedEntityType {
  attraction('ATTRACTION'),
  activity('ACTIVITY'),
  guide('GUIDE'),
  user('USER'),
  post('POST');

  const SavedEntityType(this.wireValue);

  final String wireValue;

  static SavedEntityType fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('entity_type must be a string.');
    }

    return switch (value) {
      'ATTRACTION' => SavedEntityType.attraction,
      'ACTIVITY' => SavedEntityType.activity,
      'GUIDE' => SavedEntityType.guide,
      'USER' => SavedEntityType.user,
      'POST' => SavedEntityType.post,
      _ => throw FormatException('Unsupported Saved entity_type: $value.'),
    };
  }
}

final class SavedTarget {
  SavedTarget({required this.entityType, required String entityId})
    : entityId = _validateEntityId(entityId);

  static SavedTarget? tryCreate({
    required SavedEntityType entityType,
    required String? entityId,
  }) {
    if (entityId == null) return null;
    try {
      return SavedTarget(entityType: entityType, entityId: entityId);
    } on ArgumentError {
      return null;
    }
  }

  factory SavedTarget.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'entity_type', 'entity_id'});
    final entityId = json['entity_id'];
    if (entityId is! String) {
      throw const FormatException('entity_id must be a string.');
    }

    try {
      return SavedTarget(
        entityType: SavedEntityType.fromWireValue(json['entity_type']),
        entityId: entityId,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid entity_id.');
    }
  }

  final SavedEntityType entityType;
  final String entityId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'entity_type': entityType.wireValue,
      'entity_id': entityId,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SavedTarget &&
            entityType == other.entityType &&
            entityId == other.entityId;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId);

  @override
  String toString() {
    return 'SavedTarget(${entityType.wireValue}, <opaque>)';
  }

  static String _validateEntityId(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'entityId', 'Must not be empty.');
    }
    if (value.trim() != value) {
      throw ArgumentError.value(
        value,
        'entityId',
        'Must not contain surrounding whitespace.',
      );
    }
    if (_controlCharacterPattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'entityId',
        'Must not contain control characters.',
      );
    }
    if (utf8.encode(value).length > 512) {
      throw ArgumentError.value(
        value,
        'entityId',
        'Must not exceed 512 UTF-8 bytes.',
      );
    }
    return value;
  }
}

final RegExp _controlCharacterPattern = RegExp(r'[\x00-\x1F\x7F-\x9F]');

void _requireExactKeys(Map<String, dynamic> json, Set<String> expectedKeys) {
  final actualKeys = json.keys.toSet();
  if (actualKeys.length != expectedKeys.length ||
      !actualKeys.containsAll(expectedKeys)) {
    throw FormatException(
      'SavedTarget keys must be exactly ${expectedKeys.toList()..sort()}.',
    );
  }
}
