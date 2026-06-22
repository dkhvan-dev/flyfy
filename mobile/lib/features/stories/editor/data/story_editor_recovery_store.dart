import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/story_document.dart';

class StoryEditorRecoveryStore {
  StoryEditorRecoveryStore({
    StoryEditorRecoveryStorage? storage,
    Future<SharedPreferences> Function()? prefsProvider,
    this.maxSnapshotBytes = 128 * 1024,
    this.maxSnapshotsPerUser = 8,
  }) : _storage =
           storage ??
           _SharedPreferencesRecoveryStorage(
             prefsProvider ?? SharedPreferences.getInstance,
           );

  static const int _schemaVersion = 1;
  static const String _keyPrefix = 'story_editor_recovery.v1';

  final StoryEditorRecoveryStorage _storage;
  final int maxSnapshotBytes;
  final int maxSnapshotsPerUser;

  static String storageKey({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) {
    final normalizedUserId = _requiredTrim(userId, 'userId');
    final entityKind = _normalizeNullable(storyId) != null ? 'story' : 'local';
    final entityId =
        _normalizeNullable(storyId) ??
        _normalizeNullable(localDraftId) ??
        (throw ArgumentError('Either storyId or localDraftId is required.'));

    return [
      _keyPrefix,
      Uri.encodeComponent(normalizedUserId),
      entityKind,
      Uri.encodeComponent(entityId),
    ].join('.');
  }

  /// Stores a temporary crash-recovery draft in SharedPreferences.
  ///
  /// This is plaintext device-local JSON because Task 10 is constrained to the
  /// existing local storage dependency. It is not a source of truth and must
  /// never contain auth tokens, cookies, OTPs, account secrets, or raw private
  /// account data. Keep this store limited to recoverable editor state until a
  /// dedicated encrypted draft store is introduced.
  Future<bool> save(StoryEditorRecoverySnapshot snapshot) async {
    final key = storageKey(
      userId: snapshot.userId,
      storyId: snapshot.storyId,
      localDraftId: snapshot.localDraftId,
    );
    final encoded = jsonEncode(snapshot.toJson());
    if (utf8.encode(encoded).length > maxSnapshotBytes) {
      return false;
    }

    final existingSnapshot = await _loadExistingSnapshotForSave(key);
    if (existingSnapshot != null &&
        existingSnapshot.lastLocalEditAt.isAfter(snapshot.lastLocalEditAt)) {
      return false;
    }

    final didPersist = await _storage.setString(key, encoded);
    if (!didPersist) {
      return false;
    }
    await _cleanupUserSnapshots(userId: snapshot.userId);
    return true;
  }

  Future<StoryEditorRecoverySnapshot?> load({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) async {
    final key = storageKey(
      userId: userId,
      storyId: storyId,
      localDraftId: localDraftId,
    );
    final raw = await _storage.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _storage.remove(key);
        return null;
      }
      final snapshot = StoryEditorRecoverySnapshot.fromJson(decoded);
      if (snapshot.storageKey != key) {
        await _storage.remove(key);
        return null;
      }
      return snapshot;
    } on _UnsupportedRecoverySchemaException {
      return null;
    } catch (_) {
      await _storage.remove(key);
      return null;
    }
  }

  Future<bool> clear({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) async {
    return _storage.remove(
      storageKey(userId: userId, storyId: storyId, localDraftId: localDraftId),
    );
  }

  Future<StoryEditorRecoverySnapshot?> _loadExistingSnapshotForSave(
    String key,
  ) async {
    final raw = await _storage.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final snapshot = StoryEditorRecoverySnapshot.fromJson(decoded);
      return snapshot.storageKey == key ? snapshot : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cleanupUserSnapshots({required String userId}) async {
    final normalizedUserId = _requiredTrim(userId, 'userId');
    final userPrefix = '$_keyPrefix.${Uri.encodeComponent(normalizedUserId)}.';
    final entries = <_StoredSnapshotEntry>[];

    final keys = await _storage.getKeys();
    for (final key in keys.where((key) => key.startsWith(userPrefix))) {
      final raw = await _storage.getString(key);
      if (raw == null || raw.trim().isEmpty) {
        await _storage.remove(key);
        continue;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          await _storage.remove(key);
          continue;
        }
        final snapshot = StoryEditorRecoverySnapshot.fromJson(decoded);
        if (snapshot.storageKey != key) {
          await _storage.remove(key);
          continue;
        }
        entries.add(_StoredSnapshotEntry(key, snapshot.lastLocalEditAt));
      } on _UnsupportedRecoverySchemaException {
        // Preserve future-schema snapshots for forward/downgrade safety.
      } catch (_) {
        await _storage.remove(key);
      }
    }

    if (entries.length <= maxSnapshotsPerUser) {
      return;
    }

    entries.sort((a, b) => a.lastLocalEditAt.compareTo(b.lastLocalEditAt));
    final removeCount = entries.length - maxSnapshotsPerUser;
    for (final entry in entries.take(removeCount)) {
      await _storage.remove(entry.key);
    }
  }
}

abstract class StoryEditorRecoveryStorage {
  Future<Set<String>> getKeys();

  Future<String?> getString(String key);

  Future<bool> setString(String key, String value);

  Future<bool> remove(String key);
}

class _SharedPreferencesRecoveryStorage implements StoryEditorRecoveryStorage {
  _SharedPreferencesRecoveryStorage(this._prefsProvider);

  final Future<SharedPreferences> Function() _prefsProvider;

  @override
  Future<Set<String>> getKeys() async {
    final prefs = await _prefsProvider();
    return prefs.getKeys();
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await _prefsProvider();
    return prefs.getString(key);
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await _prefsProvider();
    return prefs.remove(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    final prefs = await _prefsProvider();
    return prefs.setString(key, value);
  }
}

class _StoredSnapshotEntry {
  const _StoredSnapshotEntry(this.key, this.lastLocalEditAt);

  final String key;
  final DateTime lastLocalEditAt;
}

class StoryEditorRecoverySnapshot {
  StoryEditorRecoverySnapshot({
    required String userId,
    required this.metadata,
    required this.document,
    required DateTime lastLocalEditAt,
    String? storyId,
    String? localDraftId,
    String? communityId,
    List<StoryEditorPendingMediaReference> pendingMediaReferences = const [],
    this.lastRemoteRevision,
  }) : userId = _requiredTrim(userId, 'userId'),
       storyId = _normalizeNullable(storyId),
       localDraftId = _normalizeNullable(localDraftId),
       communityId = _normalizeNullable(communityId),
       lastLocalEditAt = lastLocalEditAt.toUtc(),
       _pendingMediaReferences = List.unmodifiable(pendingMediaReferences) {
    if (this.storyId == null && this.localDraftId == null) {
      throw ArgumentError('Either storyId or localDraftId is required.');
    }
  }

  factory StoryEditorRecoverySnapshot.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _intFromJson(json['schemaVersion']);
    if (schemaVersion != StoryEditorRecoveryStore._schemaVersion) {
      throw _UnsupportedRecoverySchemaException(schemaVersion);
    }

    return StoryEditorRecoverySnapshot(
      userId: _requiredStringFromJson(json['userId'], 'userId'),
      storyId: _nullableStringFromJson(json['storyId']),
      localDraftId: _nullableStringFromJson(json['localDraftId']),
      communityId: _nullableStringFromJson(json['communityId']),
      metadata: StoryEditorMetadataDraft.fromJson(
        _mapFromJson(json['metadata']),
      ),
      document: _documentFromJson(_mapFromJson(json['document'])),
      pendingMediaReferences: _listFromJson(
        json['pendingMediaReferences'],
      ).map(StoryEditorPendingMediaReference.fromJson).toList(growable: false),
      lastRemoteRevision: _nullableIntFromJson(json['lastRemoteRevision']),
      lastLocalEditAt: DateTime.parse(
        _requiredStringFromJson(json['lastLocalEditAt'], 'lastLocalEditAt'),
      ),
    );
  }

  final String userId;
  final String? storyId;
  final String? localDraftId;
  final String? communityId;
  final StoryEditorMetadataDraft metadata;
  final StoryDocument document;
  final int? lastRemoteRevision;
  final DateTime lastLocalEditAt;
  final List<StoryEditorPendingMediaReference> _pendingMediaReferences;

  List<StoryEditorPendingMediaReference> get pendingMediaReferences =>
      _pendingMediaReferences;

  String get storageKey => StoryEditorRecoveryStore.storageKey(
    userId: userId,
    storyId: storyId,
    localDraftId: localDraftId,
  );

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': StoryEditorRecoveryStore._schemaVersion,
      'userId': userId,
      if (storyId != null) 'storyId': storyId,
      if (localDraftId != null) 'localDraftId': localDraftId,
      if (communityId != null) 'communityId': communityId,
      'metadata': metadata.toJson(),
      'document': _documentToJson(document),
      'pendingMediaReferences': _pendingMediaReferences
          .map((reference) => reference.toJson())
          .toList(growable: false),
      if (lastRemoteRevision != null) 'lastRemoteRevision': lastRemoteRevision,
      'lastLocalEditAt': lastLocalEditAt.toUtc().toIso8601String(),
    };
  }
}

class StoryEditorMetadataDraft {
  StoryEditorMetadataDraft({
    required this.title,
    required this.format,
    required this.category,
    required this.status,
    this.coverFileId,
    this.placeName,
    this.placeCountryCode,
    this.placeCityId,
    List<String> tags = const [],
    Map<String, Object?> metadata = const {},
  }) : tags = List.unmodifiable(
         tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
       ),
       metadata = Map.unmodifiable(_sanitizeMetadata(metadata));

  factory StoryEditorMetadataDraft.fromJson(Map<String, dynamic> json) {
    return StoryEditorMetadataDraft(
      title: _stringFromJson(json['title'], fieldName: 'title'),
      format: _stringFromJson(json['format'], fieldName: 'format'),
      category: _stringFromJson(json['category'], fieldName: 'category'),
      status: _stringFromJson(json['status'], fieldName: 'status'),
      coverFileId: _nullableStringFromJson(json['coverFileId']),
      placeName: _nullableStringFromJson(json['placeName']),
      placeCountryCode: _nullableStringFromJson(json['placeCountryCode']),
      placeCityId: _nullableStringFromJson(json['placeCityId']),
      tags: _stringListFromJson(json['tags']),
      metadata: _plainMapFromJson(json['metadata']),
    );
  }

  final String title;
  final String format;
  final String category;
  final String status;
  final String? coverFileId;
  final String? placeName;
  final String? placeCountryCode;
  final String? placeCityId;
  final List<String> tags;
  final Map<String, Object?> metadata;

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'format': format.trim().toUpperCase(),
      'category': category.trim().toUpperCase(),
      'status': status.trim().toUpperCase(),
      if (_normalizeNullable(coverFileId) != null)
        'coverFileId': _normalizeNullable(coverFileId),
      if (_normalizeNullable(placeName) != null)
        'placeName': _normalizeNullable(placeName),
      if (_normalizeNullable(placeCountryCode) != null)
        'placeCountryCode': _normalizeNullable(placeCountryCode)?.toUpperCase(),
      if (_normalizeNullable(placeCityId) != null)
        'placeCityId': _normalizeNullable(placeCityId),
      'tags': tags,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

class StoryEditorPendingMediaReference {
  const StoryEditorPendingMediaReference({
    required this.localMediaId,
    this.kind,
    this.status,
    this.blockId,
    this.galleryImageIndex,
    this.fileName,
    this.mimeType,
    this.byteSize,
    this.localPath,
    this.previewBytes,
  });

  factory StoryEditorPendingMediaReference.fromJson(Map<String, dynamic> json) {
    return StoryEditorPendingMediaReference(
      localMediaId: _requiredStringFromJson(
        json['localMediaId'],
        'localMediaId',
      ),
      kind: _nullableStringFromJson(json['kind']),
      status: _nullableStringFromJson(json['status']),
      blockId: _nullableStringFromJson(json['blockId']),
      galleryImageIndex: _nullableIntFromJson(json['galleryImageIndex']),
      fileName: _nullableStringFromJson(json['fileName']),
      mimeType: _nullableStringFromJson(json['mimeType']),
      byteSize: _nullableIntFromJson(json['byteSize']),
      localPath: _nullableStringFromJson(json['localPath']),
      previewBytes: _bytesFromJson(json['previewBytesBase64']),
    );
  }

  final String localMediaId;
  final String? kind;
  final String? status;
  final String? blockId;
  final int? galleryImageIndex;
  final String? fileName;
  final String? mimeType;
  final int? byteSize;
  final String? localPath;
  final Uint8List? previewBytes;

  Map<String, dynamic> toJson() {
    return {
      'localMediaId': localMediaId.trim(),
      if (_normalizeNullable(kind) != null) 'kind': kind!.trim(),
      if (_normalizeNullable(status) != null) 'status': status!.trim(),
      if (_normalizeNullable(blockId) != null) 'blockId': blockId!.trim(),
      if (galleryImageIndex != null) 'galleryImageIndex': galleryImageIndex,
      if (_normalizeNullable(fileName) != null) 'fileName': fileName!.trim(),
      if (_normalizeNullable(mimeType) != null) 'mimeType': mimeType!.trim(),
      if (byteSize != null) 'byteSize': byteSize,
      if (_normalizeNullable(localPath) != null) 'localPath': localPath!.trim(),
      if (previewBytes != null && previewBytes!.isNotEmpty)
        'previewBytesBase64': base64Encode(previewBytes!),
    };
  }
}

Map<String, dynamic> _documentToJson(StoryDocument document) {
  return {
    'version': document.version,
    'blocks': document.blocks.map(_blockToJson).toList(growable: false),
  };
}

StoryDocument _documentFromJson(Map<String, dynamic> json) {
  return StoryDocument(
    version:
        _nullableIntFromJson(json['version']) ?? StoryDocument.currentVersion,
    blocks: _listFromJson(
      json['blocks'],
    ).map(_blockFromJson).toList(growable: false),
  );
}

Map<String, dynamic> _blockToJson(StoryBlock block) {
  return {
    'id': block.id,
    'type': _blockTypeToJson(block.type),
    if (block.text != null) 'text': block.text,
    if (block.marks.isNotEmpty)
      'marks': block.marks.map(_markToJson).toList(growable: false),
    if (block.level != null) 'level': block.level,
    if (block.image != null) 'image': _imageToJson(block.image!),
    if (block.gallery != null)
      'gallery': {
        'images': block.gallery!.images
            .map(_imageToJson)
            .toList(growable: false),
      },
    if (block.place != null) 'place': _placeToJson(block.place!),
    if (block.route != null) 'route': _routeToJson(block.route!),
  };
}

StoryBlock _blockFromJson(Map<String, dynamic> json) {
  final id = _requiredStringFromJson(json['id'], 'block.id');
  final text = _stringFromJson(json['text'], fieldName: 'block.text');
  final marks = _listFromJson(
    json['marks'],
  ).map(_markFromJson).toList(growable: false);

  return switch (_requiredStringFromJson(json['type'], 'block.type')) {
    'paragraph' => StoryBlock.paragraph(id: id, text: text, marks: marks),
    'heading' => StoryBlock.heading(
      id: id,
      text: text,
      level: _nullableIntFromJson(json['level']) ?? 1,
      marks: marks,
    ),
    'bulleted_list' => StoryBlock.bulletedList(
      id: id,
      text: text,
      marks: marks,
    ),
    'numbered_list' => StoryBlock.numberedList(
      id: id,
      text: text,
      marks: marks,
    ),
    'quote' => StoryBlock.quote(id: id, text: text, marks: marks),
    'callout' => StoryBlock.callout(id: id, text: text, marks: marks),
    'image' => StoryBlock.image(
      id: id,
      image: _imageFromJson(_mapFromJson(json['image'])),
    ),
    'gallery' => StoryBlock.gallery(
      id: id,
      gallery: StoryGalleryPayload(
        images: _listFromJson(
          _mapFromJson(json['gallery'])['images'],
        ).map(_imageFromJson).toList(growable: false),
      ),
    ),
    'divider' => StoryBlock.divider(id: id),
    'place_reference' => StoryBlock.placeReference(
      id: id,
      place: _placeFromJson(_mapFromJson(json['place'])),
    ),
    'route_reference' => StoryBlock.routeReference(
      id: id,
      route: _routeFromJson(_mapFromJson(json['route'])),
    ),
    _ => throw FormatException('Unsupported story block type: ${json['type']}'),
  };
}

Map<String, dynamic> _markToJson(StoryInlineMark mark) {
  return {
    'type': _markTypeToJson(mark.type),
    'start': mark.start,
    'end': mark.end,
    if (_normalizeNullable(mark.url) != null) 'url': mark.url!.trim(),
  };
}

StoryInlineMark _markFromJson(Map<String, dynamic> json) {
  final start = _intFromJson(json['start']);
  final end = _intFromJson(json['end']);
  return switch (_requiredStringFromJson(json['type'], 'mark.type')) {
    'bold' => StoryInlineMark.bold(start: start, end: end),
    'italic' => StoryInlineMark.italic(start: start, end: end),
    'underline' => StoryInlineMark.underline(start: start, end: end),
    'strikethrough' => StoryInlineMark.strikethrough(start: start, end: end),
    'link' => StoryInlineMark.link(
      start: start,
      end: end,
      url: _requiredStringFromJson(json['url'], 'mark.url'),
    ),
    _ => throw FormatException('Unsupported story mark type: ${json['type']}'),
  };
}

Map<String, dynamic> _imageToJson(StoryImagePayload image) {
  return {'fileId': image.fileId.trim(), 'uploadState': image.uploadState.name};
}

StoryImagePayload _imageFromJson(Map<String, dynamic> json) {
  return StoryImagePayload(
    fileId: _stringFromJson(json['fileId'], fieldName: 'image.fileId'),
    uploadState: _uploadStateFromJson(json['uploadState']),
  );
}

Map<String, dynamic> _placeToJson(StoryPlaceReference place) {
  return {
    'name': place.name.trim(),
    if (_normalizeNullable(place.placeId) != null)
      'placeId': place.placeId!.trim(),
    if (_normalizeNullable(place.countryCode) != null)
      'countryCode': place.countryCode!.trim().toUpperCase(),
    if (_normalizeNullable(place.cityId) != null)
      'cityId': place.cityId!.trim(),
    if (place.latitude != null) 'latitude': place.latitude,
    if (place.longitude != null) 'longitude': place.longitude,
  };
}

StoryPlaceReference _placeFromJson(Map<String, dynamic> json) {
  return StoryPlaceReference(
    name: _requiredStringFromJson(json['name'], 'place.name'),
    placeId: _nullableStringFromJson(json['placeId']),
    countryCode: _nullableStringFromJson(json['countryCode']),
    cityId: _nullableStringFromJson(json['cityId']),
    latitude: _nullableDoubleFromJson(json['latitude']),
    longitude: _nullableDoubleFromJson(json['longitude']),
  );
}

Map<String, dynamic> _routeToJson(StoryRouteReference route) {
  return {
    'routeId': route.routeId.trim(),
    'title': route.title.trim(),
    if (_normalizeNullable(route.description) != null)
      'description': route.description!.trim(),
    if (_normalizeNullable(route.profile) != null)
      'profile': route.profile!.trim(),
    if (route.distanceMeters != null) 'distanceMeters': route.distanceMeters,
    if (route.durationSeconds != null) 'durationSeconds': route.durationSeconds,
    if (route.stopsCount != null) 'stopsCount': route.stopsCount,
    if (_normalizeNullable(route.shareUrl) != null)
      'shareUrl': route.shareUrl!.trim(),
  };
}

StoryRouteReference _routeFromJson(Map<String, dynamic> json) {
  return StoryRouteReference(
    routeId: _requiredStringFromJson(json['routeId'], 'route.routeId'),
    title: _requiredStringFromJson(json['title'], 'route.title'),
    description: _nullableStringFromJson(json['description']),
    profile: _nullableStringFromJson(json['profile']),
    distanceMeters: _nullableIntFromJson(json['distanceMeters']),
    durationSeconds: _nullableIntFromJson(json['durationSeconds']),
    stopsCount: _nullableIntFromJson(json['stopsCount']),
    shareUrl: _nullableStringFromJson(json['shareUrl']),
  );
}

String _blockTypeToJson(StoryBlockType type) {
  return switch (type) {
    StoryBlockType.paragraph => 'paragraph',
    StoryBlockType.heading => 'heading',
    StoryBlockType.bulletedList => 'bulleted_list',
    StoryBlockType.numberedList => 'numbered_list',
    StoryBlockType.quote => 'quote',
    StoryBlockType.callout => 'callout',
    StoryBlockType.image => 'image',
    StoryBlockType.gallery => 'gallery',
    StoryBlockType.divider => 'divider',
    StoryBlockType.placeReference => 'place_reference',
    StoryBlockType.routeReference => 'route_reference',
  };
}

String _markTypeToJson(StoryInlineMarkType type) {
  return switch (type) {
    StoryInlineMarkType.bold => 'bold',
    StoryInlineMarkType.italic => 'italic',
    StoryInlineMarkType.underline => 'underline',
    StoryInlineMarkType.strikethrough => 'strikethrough',
    StoryInlineMarkType.link => 'link',
  };
}

StoryUploadState _uploadStateFromJson(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return StoryUploadState.complete;
  }
  return StoryUploadState.values.firstWhere(
    (state) => state.name == raw,
    orElse: () => StoryUploadState.complete,
  );
}

Uint8List? _bytesFromJson(Object? value) {
  final raw = _normalizeNullable(value?.toString());
  if (raw == null) return null;
  try {
    return Uint8List.fromList(base64Decode(raw));
  } on FormatException {
    return null;
  }
}

Map<String, Object?> _sanitizeMetadata(Map<String, Object?> metadata) {
  const recoverableMetadataKeys = {
    'clientTraceId',
    'editorSessionId',
    'draftSource',
  };
  final sanitized = <String, Object?>{};
  for (final entry in metadata.entries) {
    final key = entry.key.trim();
    if (!recoverableMetadataKeys.contains(key)) {
      continue;
    }
    final value = entry.value;
    if (value == null || value is String || value is num || value is bool) {
      sanitized[key] = value;
    }
  }
  return sanitized;
}

String _requiredTrim(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '$name is required.');
  }
  return normalized;
}

String? _normalizeNullable(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

String _requiredStringFromJson(Object? value, String fieldName) {
  if (value is! String) {
    throw FormatException('Expected string value for $fieldName.');
  }
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw FormatException('Expected non-empty string value for $fieldName.');
  }
  return normalized;
}

String _stringFromJson(Object? value, {required String fieldName}) {
  if (value == null) {
    return '';
  }
  if (value is! String) {
    throw FormatException('Expected string value for $fieldName.');
  }
  return value;
}

String? _nullableStringFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw const FormatException('Expected optional string value.');
  }
  return _normalizeNullable(value);
}

int _intFromJson(Object? value) {
  final parsed = _nullableIntFromJson(value);
  if (parsed == null) {
    throw FormatException('Expected integer value, got $value.');
  }
  return parsed;
}

int? _nullableIntFromJson(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _nullableDoubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

Map<String, dynamic> _mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

Map<String, Object?> _plainMapFromJson(Object? value) {
  return _sanitizeMetadata(Map<String, Object?>.from(_mapFromJson(value)));
}

List<Map<String, dynamic>> _listFromJson(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_mapFromJson).toList(growable: false);
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

class _UnsupportedRecoverySchemaException implements Exception {
  const _UnsupportedRecoverySchemaException(this.schemaVersion);

  final int schemaVersion;
}
